{
module MdrPars where
import MdrLexr
}

%name mdr
%tokentype { Token }
%error { parseError }
%lexer {alexMonadScan >>=} {EOF}
%monad { Alex }

%token
  include { Include _ _ }
  codeini { CodeIni _ _ _ _ }
  codeend { CodeEnd _ _ }
  execcmd { ExecCmd _ _ }
  content { Content _ _ }
  eof     { EOF }
%%
Ast :: { [[Token]] }
  : Ast Part { $1 ++ [$2] }
  | Part { [$1] }
  | eof {[]}
Part :: { [Token] }
  : codeini Stmts codeend { $1 : $2 }
  | Stmts           { $1 }
  | codeini Stmts   {% mdrError "unfinished block" $ last $2 }
  | codeini         {% mdrError "unfinished block" $1 }
  | codeend         {% mdrError "unstarted block" $1 }
  | codeini codeend {% mdrError "empty block" $2 }

Stmts :: { [Token] }
  : Stmts Stmt { $1 ++ $2 }
  | Stmt { $1 }

Stmt :: { [Token] }
  : Stmt Exp { $1 ++ [$2] }
  | Exp { [$1] }

Exp :: { Token }
  : include { $1 }
  | execcmd { $1 }
  | Content { $1 }

Content :: { Token }
  : Content content { $1 ~~ $2 }
  | content { $1 }

{
(~~) :: Token -> Token -> Token
(Content a _) ~~ (Content b c) = Content (a ++ b) c

mdrError a tok = alexError $ tokErr tok a

parseError :: Token -> Alex a
parseError x = Alex $ \_ -> Left "parser error"
}
