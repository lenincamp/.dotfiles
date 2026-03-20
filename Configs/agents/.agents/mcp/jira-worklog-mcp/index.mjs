import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { z } from "zod";

const siteUrl = process.env.JIRA_SITE_URL;
const userEmail = process.env.JIRA_USER_EMAIL;
const apiToken = process.env.JIRA_API_TOKEN;
const tempoApiToken = process.env.TEMPO_API_TOKEN;
const rawTempoApiBaseUrl = (process.env.TEMPO_API_BASE_URL || "https://api.tempo.io").replace(/\/$/, "");
const tempoTypeAttributeKey = process.env.TEMPO_ATTR_TYPE_KEY || "Type";
const tempoWorkingAttributeKey = process.env.TEMPO_ATTR_WORKING_KEY || "Working";
const tempoDefaultType = process.env.TEMPO_DEFAULT_TYPE;
const tempoDefaultWorking = process.env.TEMPO_DEFAULT_WORKING;

const jiraIssueIdCache = new Map();
let jiraCurrentUserCache = null;
const nonWorkingDayMonthCache = new Map();

function safeJson(text) {
  try {
    return JSON.parse(text);
  } catch {
    return { raw: text };
  }
}

function compactError(data, text) {
  const detail = data ? JSON.stringify(data) : text;
  return String(detail || "").slice(0, 1200);
}

function requireJiraEnv() {
  const missing = [];
  if (!siteUrl) missing.push("JIRA_SITE_URL");
  if (!userEmail) missing.push("JIRA_USER_EMAIL");
  if (!apiToken) missing.push("JIRA_API_TOKEN");
  if (missing.length) {
    throw new Error(`Missing required env vars: ${missing.join(", ")}`);
  }
}

function jiraUrl(path) {
  return `${siteUrl.replace(/\/$/, "")}/rest/api/3${path}`;
}

function jiraAuthHeader() {
  const basic = Buffer.from(`${userEmail}:${apiToken}`).toString("base64");
  return `Basic ${basic}`;
}

async function jiraRequest(method, path, body) {
  requireJiraEnv();
  const res = await fetch(jiraUrl(path), {
    method,
    headers: {
      Accept: "application/json",
      "Content-Type": "application/json",
      Authorization: jiraAuthHeader()
    },
    body: body ? JSON.stringify(body) : undefined
  });

  const text = await res.text();
  const data = text ? safeJson(text) : null;
  if (!res.ok) {
    throw new Error(`Jira API ${method} ${path} failed (${res.status}): ${compactError(data, text)}`);
  }

  return data;
}

function hasTempoAuth() {
  return Boolean(tempoApiToken);
}

function getTempoBaseCandidates() {
  const normalized = rawTempoApiBaseUrl;
  const candidates = [];

  const looksLikeUiUrl =
    normalized.includes("atlassian.net") ||
    normalized.includes("/plugins/servlet/ac/io.tempo.jira") ||
    normalized.includes("tempo-app#!/");

  if (!looksLikeUiUrl) {
    candidates.push(normalized);
  }

  for (const host of ["https://api.us.tempo.io", "https://api.eu.tempo.io", "https://api.tempo.io"]) {
    if (!candidates.includes(host)) {
      candidates.push(host);
    }
  }

  return candidates;
}

async function tempoRequest(method, path, body) {
  if (!hasTempoAuth()) {
    throw new Error("Missing TEMPO_API_TOKEN to write Tempo worklogs");
  }

  const failures = [];
  for (const baseUrl of getTempoBaseCandidates()) {
    const res = await fetch(`${baseUrl}${path}`, {
      method,
      headers: {
        Accept: "application/json",
        "Content-Type": "application/json",
        Authorization: `Bearer ${tempoApiToken}`
      },
      body: body ? JSON.stringify(body) : undefined
    });

    const text = await res.text();
    const data = text ? safeJson(text) : null;

    if (res.ok) {
      return data;
    }

    failures.push(`${baseUrl} -> (${res.status}) ${compactError(data, text)}`);
    if ((res.status === 401 || res.status === 403) && baseUrl.includes("api.")) {
      break;
    }
  }

  throw new Error(`Tempo API ${method} ${path} failed: ${failures.join(" | ")}`);
}

function parseStartedForTempo(started) {
  const value = String(started);
  const match = value.match(/^(\d{4}-\d{2}-\d{2})T(\d{2}:\d{2}:\d{2})/);
  if (!match) {
    throw new Error("Invalid started format. Expected YYYY-MM-DDTHH:mm:ss.SSSZ");
  }
  return { startDate: match[1], startTime: match[2] };
}

function parseTimeSpentToSeconds(timeSpent) {
  const input = String(timeSpent).trim().toLowerCase();
  const parts = [...input.matchAll(/(\d+)\s*([dhms])/g)];
  if (parts.length === 0) {
    throw new Error("Invalid timeSpent format. Examples: 2h, 30m, 1h 30m");
  }

  let total = 0;
  for (const [, amountRaw, unit] of parts) {
    const amount = Number(amountRaw);
    if (unit === "d") total += amount * 8 * 3600;
    if (unit === "h") total += amount * 3600;
    if (unit === "m") total += amount * 60;
    if (unit === "s") total += amount;
  }

  return total;
}

function monthFromDate(date) {
  return date.slice(0, 7);
}

function monthBounds(yearMonth) {
  const [year, month] = yearMonth.split("-").map(Number);
  const first = new Date(Date.UTC(year, month - 1, 1));
  const last = new Date(Date.UTC(year, month, 0));
  const fmt = (d) => d.toISOString().slice(0, 10);
  return { from: fmt(first), to: fmt(last) };
}

function parseRequiredSeconds(item) {
  const candidates = [
    item?.requiredSeconds,
    item?.requiredTimeSeconds,
    item?.required?.seconds,
    item?.required?.requiredSeconds,
    item?.requiredWorkSeconds,
    item?.workloadSeconds
  ];

  for (const value of candidates) {
    if (typeof value === "number" && Number.isFinite(value)) {
      return value;
    }
  }
  return null;
}

function looksLikeHoliday(item) {
  return (
    item?.isHoliday === true ||
    item?.holiday === true ||
    Boolean(item?.holidayName) ||
    Boolean(item?.holidayType) ||
    String(item?.type || "").toUpperCase().includes("HOLIDAY")
  );
}

async function getNonWorkingDaysForMonth(accountId, yearMonth) {
  const cacheKey = `${accountId}:${yearMonth}`;
  if (nonWorkingDayMonthCache.has(cacheKey)) {
    return nonWorkingDayMonthCache.get(cacheKey);
  }

  const { from, to } = monthBounds(yearMonth);
  const page = await tempoRequest(
    "GET",
    `/4/user-schedule/${encodeURIComponent(accountId)}?from=${from}&to=${to}`
  );

  const results = page?.results || [];
  const nonWorkingDates = new Set();

  for (const item of results) {
    if (typeof item?.date !== "string") continue;
    const required = parseRequiredSeconds(item);
    if (looksLikeHoliday(item) || required === 0) {
      nonWorkingDates.add(item.date);
    }
  }

  nonWorkingDayMonthCache.set(cacheKey, nonWorkingDates);
  return nonWorkingDates;
}

async function assertDateIsWorkingDay(accountId, started) {
  const date = parseStartedForTempo(started).startDate;
  const yearMonth = monthFromDate(date);

  let nonWorkingDates;
  try {
    nonWorkingDates = await getNonWorkingDaysForMonth(accountId, yearMonth);
  } catch (error) {
    throw new Error(
      `Cannot validate holiday/non-working day for ${date}. ` +
      `Worklog rejected for safety. Detail: ${String(error?.message || error)}`
    );
  }

  if (nonWorkingDates.has(date)) {
    throw new Error(`Worklog rejected: ${date} is a holiday/non-working day in Tempo schedule.`);
  }
}

async function getJiraIssueId(issueKey) {
  if (jiraIssueIdCache.has(issueKey)) return jiraIssueIdCache.get(issueKey);
  const issue = await jiraRequest("GET", `/issue/${encodeURIComponent(issueKey)}?fields=summary`);
  const issueId = Number(issue?.id);
  if (!issueId) {
    throw new Error(`Unable to resolve Jira issue id for ${issueKey}`);
  }
  jiraIssueIdCache.set(issueKey, issueId);
  return issueId;
}

async function getJiraCurrentAccountId() {
  if (jiraCurrentUserCache) return jiraCurrentUserCache;
  const me = await jiraRequest("GET", "/myself");
  if (!me?.accountId) {
    throw new Error("Unable to resolve Jira current user accountId");
  }
  jiraCurrentUserCache = me.accountId;
  return jiraCurrentUserCache;
}

async function getTempoWorklogIdFromJiraWorklogId(jiraWorklogId) {
  const mapped = await tempoRequest("POST", "/4/worklogs/jira-to-tempo", {
    jiraWorklogIds: [Number(jiraWorklogId)]
  });
  const first = mapped?.results?.[0];
  const tempoWorklogId = first?.tempoWorklogId || first?.id;
  if (!tempoWorklogId) {
    throw new Error(`No Tempo worklog mapping found for Jira worklog ${jiraWorklogId}`);
  }
  return Number(tempoWorklogId);
}

async function getJiraWorklogIdFromTempoWorklogId(tempoWorklogId) {
  const mapped = await tempoRequest("POST", "/4/worklogs/tempo-to-jira", {
    tempoWorklogIds: [Number(tempoWorklogId)]
  });
  const first = mapped?.results?.[0];
  return first?.jiraWorklogId ? String(first.jiraWorklogId) : null;
}

function buildTempoAttributes({ tempoType, tempoWorking, tempoTypeKey, tempoWorkingKey }) {
  return {
    [tempoTypeKey || tempoTypeAttributeKey]: tempoType || tempoDefaultType,
    [tempoWorkingKey || tempoWorkingAttributeKey]: tempoWorking || tempoDefaultWorking
  };
}

function normalizeTempoStartTime(startTime) {
  if (typeof startTime === "string") return startTime;
  if (typeof startTime !== "number" || Number.isNaN(startTime)) return undefined;
  const total = Math.max(0, Math.floor(startTime));
  const hours = String(Math.floor(total / 3600)).padStart(2, "0");
  const minutes = String(Math.floor((total % 3600) / 60)).padStart(2, "0");
  const seconds = String(total % 60).padStart(2, "0");
  return `${hours}:${minutes}:${seconds}`;
}

async function upsertTempoWorkAttributes(tempoWorklogId, attributes) {
  const attrList = Object.entries(attributes)
    .filter(([, value]) => typeof value === "string" && value.trim().length > 0)
    .map(([key, value]) => ({ key, value }));

  if (attrList.length === 0) {
    return { updated: false };
  }

  try {
    await tempoRequest("POST", "/4/worklogs/work-attribute-values", [
      {
        tempoWorklogId,
        attributeValues: attrList
      }
    ]);
    return { updated: true, strategy: "create" };
  } catch {
    const existing = await tempoRequest("GET", `/4/worklogs/${tempoWorklogId}`);
    const merged = {};
    for (const item of existing?.attributes?.values || []) {
      if (item?.key && typeof item?.value === "string") {
        merged[item.key] = item.value;
      }
    }
    for (const { key, value } of attrList) {
      merged[key] = value;
    }

    await tempoRequest("PUT", `/4/worklogs/${tempoWorklogId}`, {
      authorAccountId: existing?.author?.accountId,
      issueId: Number(existing?.issue?.id),
      timeSpentSeconds: Number(existing?.timeSpentSeconds),
      startDate: existing?.startDate,
      startTime: normalizeTempoStartTime(existing?.startTime),
      description: existing?.description || "",
      billableSeconds: typeof existing?.billableSeconds === "number" ? existing.billableSeconds : undefined,
      attributes: Object.entries(merged).map(([key, value]) => ({ key, value }))
    });

    return { updated: true, strategy: "update" };
  }
}

async function createWorklogDirectInTempo({ issueKey, timeSpent, started, comment, tempoType, tempoWorking, tempoTypeKey, tempoWorkingKey }) {
  const issueId = await getJiraIssueId(issueKey);
  const authorAccountId = await getJiraCurrentAccountId();
  await assertDateIsWorkingDay(authorAccountId, started);

  const { startDate, startTime } = parseStartedForTempo(started);
  const attrs = buildTempoAttributes({ tempoType, tempoWorking, tempoTypeKey, tempoWorkingKey });

  const created = await tempoRequest("POST", "/4/worklogs", {
    authorAccountId,
    issueId,
    startDate,
    startTime,
    timeSpentSeconds: parseTimeSpentToSeconds(timeSpent),
    description: comment || "",
    attributes: Object.entries(attrs)
      .filter(([, value]) => typeof value === "string" && value.trim())
      .map(([key, value]) => ({ key, value }))
  });

  const tempoWorklogId = Number(created?.tempoWorklogId);
  const jiraWorklogId = await getJiraWorklogIdFromTempoWorklogId(tempoWorklogId);

  return {
    jiraWorklogId,
    tempoWorklogId,
    started,
    timeSpent
  };
}

async function updateWorklogDirectInTempo({ issueKey, worklogId, timeSpent, started, comment, tempoType, tempoWorking, tempoTypeKey, tempoWorkingKey }) {
  const tempoWorklogId = await getTempoWorklogIdFromJiraWorklogId(worklogId);
  const existing = await tempoRequest("GET", `/4/worklogs/${tempoWorklogId}`);
  const authorAccountId = existing?.author?.accountId || (await getJiraCurrentAccountId());
  await assertDateIsWorkingDay(authorAccountId, started);

  const { startDate, startTime } = parseStartedForTempo(started);
  const attrsOverride = buildTempoAttributes({ tempoType, tempoWorking, tempoTypeKey, tempoWorkingKey });
  const mergedAttrs = {};

  for (const item of existing?.attributes?.values || []) {
    if (item?.key && typeof item?.value === "string") {
      mergedAttrs[item.key] = item.value;
    }
  }
  for (const [key, value] of Object.entries(attrsOverride)) {
    if (typeof value === "string" && value.trim()) {
      mergedAttrs[key] = value;
    }
  }

  await tempoRequest("PUT", `/4/worklogs/${tempoWorklogId}`, {
    authorAccountId,
    issueId: Number(existing?.issue?.id || (await getJiraIssueId(issueKey))),
    startDate,
    startTime,
    timeSpentSeconds: parseTimeSpentToSeconds(timeSpent),
    description: comment ?? existing?.description ?? "",
    billableSeconds: typeof existing?.billableSeconds === "number" ? existing.billableSeconds : undefined,
    attributes: Object.entries(mergedAttrs).map(([key, value]) => ({ key, value }))
  });

  return {
    issueKey,
    worklogId: String(worklogId),
    started,
    timeSpent,
    tempo: {
      updated: true,
      strategy: "tempo-direct",
      tempoWorklogId
    }
  };
}

const server = new McpServer({
  name: "jira-worklog-mcp",
  version: "0.2.0"
});

server.tool(
  "add_worklog_with_started",
  "Add Jira worklog with explicit started datetime (Tempo-compatible). Rejects holidays/non-working days.",
  {
    issueKey: z.string().min(2),
    timeSpent: z.string().min(1).describe("Examples: 2h, 30m, 1h 30m"),
    started: z.string().min(1).describe("Format: YYYY-MM-DDTHH:mm:ss.SSSZ e.g. 2026-02-02T09:00:00.000-0300"),
    comment: z.string().optional(),
    notifyUsers: z.boolean().optional(),
    tempoType: z.string().optional().describe("Tempo 'Type' attribute value"),
    tempoWorking: z.string().optional().describe("Tempo 'Working' attribute value"),
    tempoTypeKey: z.string().optional().describe("Override Tempo Type attribute key"),
    tempoWorkingKey: z.string().optional().describe("Override Tempo Working attribute key")
  },
  async ({ issueKey, timeSpent, started, comment, notifyUsers, tempoType, tempoWorking, tempoTypeKey, tempoWorkingKey }) => {
    if (hasTempoAuth()) {
      const direct = await createWorklogDirectInTempo({
        issueKey,
        timeSpent,
        started,
        comment,
        tempoType,
        tempoWorking,
        tempoTypeKey,
        tempoWorkingKey
      });

      return {
        content: [
          {
            type: "text",
            text: JSON.stringify(
              {
                ok: true,
                issueKey,
                worklogId: direct.jiraWorklogId || `tempo:${direct.tempoWorklogId}`,
                started: direct.started,
                timeSpent: direct.timeSpent,
                self: direct.jiraWorklogId
                  ? jiraUrl(`/issue/${encodeURIComponent(issueKey)}/worklog/${direct.jiraWorklogId}`)
                  : `${getTempoBaseCandidates()[0]}/4/worklogs/${direct.tempoWorklogId}`,
                tempo: {
                  updated: true,
                  strategy: "tempo-direct",
                  tempoWorklogId: direct.tempoWorklogId
                }
              },
              null,
              2
            )
          }
        ]
      };
    }

    const authorAccountId = await getJiraCurrentAccountId();
    await assertDateIsWorkingDay(authorAccountId, started);

    const body = {
      timeSpent,
      started,
      comment: comment
        ? {
            type: "doc",
            version: 1,
            content: [
              {
                type: "paragraph",
                content: [{ type: "text", text: comment }]
              }
            ]
          }
        : undefined
    };

    const query = notifyUsers === false ? "?notifyUsers=false" : "";
    const worklog = await jiraRequest("POST", `/issue/${encodeURIComponent(issueKey)}/worklog${query}`, body);

    const tempoWorklogId = await getTempoWorklogIdFromJiraWorklogId(worklog.id);
    const tempo = await upsertTempoWorkAttributes(tempoWorklogId, {
      [tempoTypeKey || tempoTypeAttributeKey]: tempoType || tempoDefaultType,
      [tempoWorkingKey || tempoWorkingAttributeKey]: tempoWorking || tempoDefaultWorking
    });

    return {
      content: [
        {
          type: "text",
          text: JSON.stringify(
            {
              ok: true,
              issueKey,
              worklogId: worklog.id,
              started: worklog.started,
              timeSpent: worklog.timeSpent,
              self: worklog.self,
              tempo
            },
            null,
            2
          )
        }
      ]
    };
  }
);

server.tool(
  "update_worklog_with_started",
  "Update Jira worklog including started datetime. Rejects holidays/non-working days.",
  {
    issueKey: z.string().min(2),
    worklogId: z.string().min(1),
    timeSpent: z.string().min(1),
    started: z.string().min(1).describe("Format: YYYY-MM-DDTHH:mm:ss.SSSZ e.g. 2026-02-02T09:00:00.000-0300"),
    comment: z.string().optional(),
    notifyUsers: z.boolean().optional(),
    tempoType: z.string().optional().describe("Tempo 'Type' attribute value"),
    tempoWorking: z.string().optional().describe("Tempo 'Working' attribute value"),
    tempoTypeKey: z.string().optional().describe("Override Tempo Type attribute key"),
    tempoWorkingKey: z.string().optional().describe("Override Tempo Working attribute key")
  },
  async ({ issueKey, worklogId, timeSpent, started, comment, notifyUsers, tempoType, tempoWorking, tempoTypeKey, tempoWorkingKey }) => {
    if (hasTempoAuth()) {
      const direct = await updateWorklogDirectInTempo({
        issueKey,
        worklogId,
        timeSpent,
        started,
        comment,
        tempoType,
        tempoWorking,
        tempoTypeKey,
        tempoWorkingKey
      });

      return {
        content: [
          {
            type: "text",
            text: JSON.stringify({ ok: true, ...direct }, null, 2)
          }
        ]
      };
    }

    const authorAccountId = await getJiraCurrentAccountId();
    await assertDateIsWorkingDay(authorAccountId, started);

    const body = {
      timeSpent,
      started,
      comment: comment
        ? {
            type: "doc",
            version: 1,
            content: [
              {
                type: "paragraph",
                content: [{ type: "text", text: comment }]
              }
            ]
          }
        : undefined
    };

    const query = notifyUsers === false ? "?notifyUsers=false" : "";
    const worklog = await jiraRequest(
      "PUT",
      `/issue/${encodeURIComponent(issueKey)}/worklog/${encodeURIComponent(worklogId)}${query}`,
      body
    );

    const tempoWorklogId = await getTempoWorklogIdFromJiraWorklogId(worklog.id);
    const tempo = await upsertTempoWorkAttributes(tempoWorklogId, {
      [tempoTypeKey || tempoTypeAttributeKey]: tempoType || tempoDefaultType,
      [tempoWorkingKey || tempoWorkingAttributeKey]: tempoWorking || tempoDefaultWorking
    });

    return {
      content: [
        {
          type: "text",
          text: JSON.stringify(
            {
              ok: true,
              issueKey,
              worklogId: worklog.id,
              started: worklog.started,
              timeSpent: worklog.timeSpent,
              self: worklog.self,
              tempo
            },
            null,
            2
          )
        }
      ]
    };
  }
);

server.tool(
  "list_issue_worklogs",
  "List Jira worklogs for an issue to verify started timestamps.",
  {
    issueKey: z.string().min(2),
    maxResults: z.number().int().positive().max(200).optional()
  },
  async ({ issueKey, maxResults = 50 }) => {
    const page = await jiraRequest("GET", `/issue/${encodeURIComponent(issueKey)}/worklog?maxResults=${maxResults}`);
    const worklogs = (page.worklogs || []).map((w) => ({
      id: w.id,
      started: w.started,
      timeSpent: w.timeSpent,
      author: w.author?.displayName,
      created: w.created,
      updated: w.updated
    }));

    return {
      content: [
        {
          type: "text",
          text: JSON.stringify({ issueKey, total: page.total, worklogs }, null, 2)
        }
      ]
    };
  }
);

server.tool(
  "list_tempo_work_attributes",
  "List available Tempo work attribute keys to identify Type/Working keys.",
  {},
  async () => {
    const page = await tempoRequest("GET", "/4/work-attributes?limit=200");
    const attrs = (page?.results || []).map((a) => ({
      key: a.key,
      name: a.name,
      type: a.type,
      required: a.required,
      values: a.values || []
    }));

    return {
      content: [
        {
          type: "text",
          text: JSON.stringify({ total: attrs.length, attributes: attrs }, null, 2)
        }
      ]
    };
  }
);

const transport = new StdioServerTransport();
await server.connect(transport);
