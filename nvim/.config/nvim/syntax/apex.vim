
" This file is part of vim-force.com plugin
"   https://github.com/neowit/vim-force.com
" File: apex.vim
" This file is part of vim-force.com plugin
" https://github.com/neowit/vim-force.com
" Author: Andrey Gavrikov
" Last Modified: 2012-03-05
" Vim syntax file

" Language:	apex
" http://vim.wikia.com/wiki/Creating_your_own_syntax_files
" http://learnvimscriptthehardway.stevelosh.com/chapters/46.html
"
"""""""""""""""""""""""""""""""""""""""""
if !exists("main_syntax")
  if version < 600
    syntax clear
  elseif exists("b:current_syntax")
    finish
  endif
  let main_syntax = 'apex'
endif

" ignore case only if user does not mind
if !exists("g:apex_syntax_case_sensitive") || !g:apex_syntax_case_sensitive
	syn case ignore
endif

syn keyword apexCommentTodo     TODO FIXME XXX TBD contained
syn match   apexLineComment     "\/\/.*" contains=@Spell,apexCommentTodo
syn region  apexComment			start="/\*"  end="\*/" contains=@Spell,apexCommentTodo
syn region  apexComment			start="/\*\*"  end="\*/" contains=@Spell,apexCommentTodo

syn keyword apexScopeDecl		global class public private protected
syn keyword apexClassDecl		extends implements interface virtual abstract
syn match   apexClassDecl		"^class\>"
syn match   apexClassDecl		"[^.]\s*\<class\>"ms=s+1
syn keyword apexMethodDecl		virtual abstract override
syn keyword apexConstant		null
syn keyword apexTypeDef			this super
syn keyword apexType			void
syn keyword apexStatement		return continue break
syn match   apexAccessor        "\<\(get\|set\)\>\_s*[{;]"me=e-1

syn keyword apexStorageClass	static final transient
syn keyword apexStructure		enum

syn keyword apexBoolean			true false
syn keyword apexTypePrimitive	Blob Boolean Date Datetime DateTime Decimal Double Integer Long String Time
syn keyword apexConditional		if then else
syn keyword apexConditional     switch on when
syn keyword apexRepeat			for while do

                                    " use \< .. \> to match the whole word
syn match 	apexPreProc			"\<\(with\|without\|inherited\) sharing\>"
syn keyword apexPreProc			testMethod
" apex annotations
syn match	apexPreProc			"@\(isTest\|future\|RemoteAction\|TestVisible\|RestResource\|Deprecated\|ReadOnly\|TestSetup\)"
syn match	apexPreProc			"@Http\(Delete\|Get\|Post\|Patch\|Put\)"
syn match	apexPreProc			"@\(AuraEnabled\|InvocableMethod\|InvocableVariable\)"
syn match	apexPreProc			"@\(SuppressWarnings\)"

syn keyword	apexException		try catch finally throw Exception
syn keyword	apexOperator		new instanceof
syn match 	apexOperator		"\(+\|-\|=\)"
syn match 	apexOperator		"!="
syn match 	apexOperator		"&&"
syn match 	apexOperator		"||"
syn match 	apexOperator		"?"
syn match 	apexOperator		":"
"syn match 	apexOperator		"*"
"syn match 	apexOperator		"/"

" apex keywords which do not fall into other categories
syn keyword	apexKeyword			webservice

"SOQL
syn keyword apexSelectKeywords	contained select from where with having limit offset
								" use \< .. \> to match the whole word
syn match	apexSelectKeywords	contained "\<\(order by\|group by\|group by rollup\|group by cube\)\>"
syn match	apexSelectKeywords	contained "\c\<\(NULLS FIRST\|NULLS LAST\|asc\|desc\)\>"
syn match	apexSelectOperator	contained "\<\(in\|not in\)\>"
syn keyword	apexSelectOperator	contained or and true false
syn keyword	apexSelectOperator	contained toLabel includes excludes convertTimezone convertCurrency
syn keyword	apexSelectOperator	contained avg count count_distinct min max sum
syn match	apexSelectConstant	contained "\<\(YESTERDAY\|TODAY\|TOMORROW\|LAST_WEEK\|THIS_WEEK\|NEXT_WEEK\|LAST_MONTH\|THIS_MONTH\|NEXT_MONTH\)\>"
syn match	apexSelectConstant	contained "\<\(LAST_90_DAYS\|NEXT_90_DAYS\|THIS_QUARTER\|LAST_QUARTER\|NEXT_QUARTER\|THIS_YEAR\|LAST_YEAR\|NEXT_YEAR\)\>"
syn match	apexSelectConstant	contained "\<\(THIS_FISCAL_QUARTER\|LAST_FISCAL_QUARTER\|NEXT_FISCAL_QUARTER\)\>"
syn match	apexSelectConstant	contained "\<\(THIS_FISCAL_YEAR\|LAST_FISCAL_YEAR\|NEXT_FISCAL_YEAR\)\>"
syn match	apexSelectConstant	contained "\<\(LAST_N_DAYS\|NEXT_N_DAYS\|NEXT_N_WEEKS\|LAST_N_WEEKS\)\>:\d\+"
syn match	apexSelectConstant	contained "\<\(NEXT_N_MONTHS\|LAST_N_MONTHS\|NEXT_N_QUARTERS\|LAST_N_QUARTERS\)\>:\d\+"
syn match	apexSelectConstant	contained "\<\(NEXT_N_YEARS\|LAST_N_YEARS\|NEXT_N_FISCAL_QUARTERS\|LAST_N_FISCAL_QUARTERS\)\>:\d\+"
syn match	apexSelectConstant	contained "\<\(NEXT_N_FISCAL_YEARS\|LAST_N_FISCAL_YEARS\)\>:\d\+"
" match YYYY-MM-DD
syn match	apexSelectDateLiteral	contained "\<\(\d\{4}-[0|1][0-2]-\([0-2]\d\|3[01]\)\)\>"
" match YYYY-MM-DDThh:mm:ss+hh:mm | YYYY-MM-DDThh:mm:ssZ
syn match	apexSelectDateLiteral	contained "\<\(\d\{4}-[0|1][0-2]-\([0-2]\d\|3[01]\)\)T\([01][0-9]\|2[0-4]\):[0-5][0-9]:[0-5][0-9]\(Z\|[+-]\([01][0-9]\|2[0-4]\)\>:[0-5][0-9]\)\>"
syn region 	apexSelectStatic	start="\[" end="]" fold transparent contains=apexSelectKeywords,apexSelectOperator,apexString,apexSelectConstant,apexSelectDateLiteral

syn match   apexSpecial	       "\\\d\d\d\|\\."
syn region  apexString	       start=+'+  skip=+\\\\\|\\'+  end=+'\|$+	contains=apexSpecial
syn match   apexNumber	       "-\=\<\d\+L\=\>\|0[xX][0-9a-fA-F]\+\>"


syn match apexDebug				"System\.debug\s*(.*);" fold contains=apexString,apexNumber,apexOperator
syn match apexAssert			"System\.assert"
syn match apexAssert			"System\.assert\(Equals\|NotEquals\)"

syn match apexSFDCCollection	"\(Map\|Set\|List\)\(\s*<\)\@="

syn keyword apexSFDCId			Id
syn keyword apexSFDCSObject		SObject
syn keyword apexStandardInterface	Comparable Iterator Iterable InstallHandler Schedulable UninstallHandler
syn match apexStandardInterface	"Auth\.RegistrationHandler\|Messaging\.InboundEmailHandler\|Process\.Plugin\|Site\.UrlRewriter"
syn match apexStandardInterface	"Database\.\(Stateful\|BatchableContext\|Batchable\|AllowsCallouts\)"

syn keyword apexVisualforceClasses	PageReference SelectOption Savepoint
syn match 	apexVisualforceClasses	"ApexPages\.\(StandardController\|StandardSetController\|Message\)"
" apex System methods
syn match 	apexSystemKeywords	"\<Database\.\(insert\|update\|delete\|undelete\|upsert\)\>"
syn match 	apexSystemKeywords	"Database\.\<\(convertLead\|countQuery\|emptyRecycleBin\|executeBatch\|getQueryLocator\|query\|rollback\|setSavepoint\)\>"
syn match 	apexSystemKeywords	"Test\.\<\(isRunningTest\|setCurrentPage\|setCurrentPageReference\|setFixedSearchResults\|setReadOnlyApplicationMode\|startTest\|stopTest\)\>"

" apex Trigger context variables and events
syn match   apexTriggerDecl		"^trigger\>"
syn match 	apexTriggerType		"\(after\|before\) \(insert\|update\|delete\|undelete\)"
syn match 	apexTriggerKeywords	"Trigger\.\(newMap\|oldMap\|new\|old\)"
syn match 	apexTriggerKeywords	"Trigger\.is\(Before\|After\|Insert\|Update\|Delete\|UnDelete\|Undelete\)"
syn match 	apexDatabaseClasses	"Database\.\<\(DeletedRecord\|DeleteResult\|DMLOptions\|DmlOptions\.AssignmentRuleHeader\|DmlOptions\.EmailHeader\)\>"
syn match 	apexDatabaseClasses	"Database\.\<\(EmptyRecycleBinResult\|Error\|GetDeletedResult\|GetUpdatedResult\|LeadConvert\|LeadConvertResult\|MergeResult\)\>"
syn match 	apexDatabaseClasses	"Database\.\<\(QueryLocator\|QueryLocatorIterator\|SaveResult\|UndeleteResult\|UpsertResult\)\>"


" Color definition
hi def link apexCommentTodo		Todo
hi def link apexComment			Comment
hi def link apexLineComment	    Comment

hi def link apexScopeDecl		StorageClass
hi def link apexClassDecl		StorageClass
hi def link apexMethodDecl      StorageClass
hi def link apexConstant		Constant
hi def link apexTypeDef			Typedef
hi def link apexType			Type
hi def link apexStatement		Statement
hi def link apexAccessor		Statement

hi def link apexStorageClass	StorageClass
hi def link apexStructure		Structure

hi def link apexBoolean			Boolean
hi def link apexTypePrimitive	Type
hi def link apexConditional		Conditional
hi def link apexRepeat			Repeat

hi def link apexPreProc			PreProc


hi def link apexException		Exception
hi def link apexOperator		Operator

hi def link apexKeyword			Keyword

hi def link apexSelectKeywords	Statement
hi def link apexSelectOperator	Operator
hi def link apexSelectConstant	Constant
hi def link apexSelectDateLiteral Constant

hi def link apexString			String
hi def link apexNumber			Number
hi def link apexDebug			Debug
hi def link apexAssert			Statement

hi def link apexSFDCCollection	Type
hi def link apexSFDCId			Type
hi def link apexSFDCSObject		Type
hi def link apexStandardInterface Type
hi def link apexVisualforceClasses Type
hi def link apexDatabaseClasses Type

hi def link apexSystemKeywords	Statement

hi def link apexTriggerDecl		StorageClass
hi def link apexTriggerType     PreProc
hi def link apexTriggerKeywords Type


let b:current_syntax = "apex"
if main_syntax == 'apex'
  unlet main_syntax
endif

" vim: ts=4
