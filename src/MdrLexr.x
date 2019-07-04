{
module MdrLexr where
}

%wrapper "monad"
$digit = 0-9      -- digits
$alpha = [a-zA-Z] -- alphabetic characters
$space = [\ \t]   -- spaces

@id        = $alpha[$alpha $digit _]*
@path      = [\. \/ $alpha $digit _]
@filename  = @path*@id\.@id
@toeol     = .* \n
-- @blk       = @```$space*
@blk       = @```$space*
@exec      = \@exec$space*
@patheol   = @filename@toeol

tokens :-
  @blk@patheol  { mkL LFileIni }
  @blk$space@id@toeol { mkL LCodeIni }
  @blk          { mkL LCodeEnd }
  "@[["@id"]]"  { mkL LInclude }
  @exec@toeol   { mkL LExecCmd }
  "@@"          { mkL LSkip }
  $white+|.|\n     { mkL LContent }

{
tokId :: Token -> String
tokId (CodeIni _ _ a _) = a
tokId _ = error "[internal] calling `tokID` on NOT a 'CodeIni' token."

tokStr :: Token -> String
tokStr (CodeIni a _ _ _) = a
tokStr (CodeEnd a _)     = a
tokStr (Include a _)     = a
tokStr (ExecCmd a _)     = a
tokStr (Content a _)     = a
tokStr (EOF) = error "[internal] calling `tokStr` on 'EOF'."

tokenSnip :: Token -> Bool
tokenSnip (CodeIni _ _ _ a) = not a
tokenSnip _ = False

stmtSnip :: [Token] -> Bool
stmtSnip x = tokenSnip $ head x

tokenFile :: Token -> Bool
tokenFile (CodeIni _ _ _ a) = a
tokenFile _ = False

stmtFile :: [Token] -> Bool
stmtFile x = tokenFile $ head x

showTokPos :: Token -> [Char]
showTokPos (CodeIni _ pos _ _) = showPosn pos
showTokPos (CodeEnd _ pos)     = showPosn pos
showTokPos (Include _ pos)     = showPosn pos
showTokPos (ExecCmd _ pos)     = showPosn pos
showTokPos (Content _ pos)     = showPosn pos
showTokPos (EOF)               = "[internal] calling `showTokPos` on 'EOF'."

showPosn :: AlexPosn -> String
showPosn (AlexPn _ line col) = "line " ++ show line ++ ":" ++ show col

mkL :: TokenClass -> AlexInput -> Int -> Alex Token
mkL c (p, _, _, str) len = let t = take len str
  in case c of 
    LFileIni -> return $! newCode (tail t) p True
    LCodeIni -> return $! newCode (tail t) p False
    LCodeEnd -> return $! CodeEnd (trim t) p
    LInclude -> return $! Include t p
    LExecCmd -> return $! ExecCmd (trimExec t) p
    LContent -> return $! Content t p
    LSkip    -> return $! Content (tail t) p

-- | skip from last dot
getFileExt :: String -> String-> String
getFileExt str sum
  | last str == '.' = "``` ." ++ sum ++ "\n"
  | otherwise = getFileExt (init str) (last str : sum)

newCode :: String -> AlexPosn -> Bool -> Token
newCode s p t = CodeIni (getFileExt (init s) []) p (trim (tailN s 3)) t

trimXXX :: (String -> String) -> (String -> Char) -> Char -> (Char -> Char -> Bool) -> String -> String
trimXXX f1 f2 c op s
  | op d c = trimXSpace f1 f2 (f1 s)
  | otherwise = s
  where
    d = f2 s 

eq :: Char -> Char -> Bool
eq a b = a == b
neq :: Char -> Char -> Bool
neq a b = not(a == b)

trimXSpace :: (String -> String) -> (String -> Char) -> String -> String
trimXSpace f1 f2 s = trimXXX f1 f2 ' ' eq s
trimFSpace :: String -> String
trimFSpace = trimXSpace tail head
trimBSpace :: String -> String
trimBSpace = trimXSpace init last

trimToSpace' ::String -> Int -> String
trimToSpace' s n
  | length s <= n = s
  | (c == ' ' || c == '\n') = take n s
  | otherwise = trimToSpace' s (n + 1)
  where
    c = s !! n

trimToSpace ::String -> String
trimToSpace s = trimToSpace' s 0

trim :: String -> String
trim s = trimToSpace $ trimFSpace s

trimExec :: String -> String
trimExec s = trimFSpace $ tailN s 5

data TokenClass =
  LInclude |
  LCodeIni |
  LFileIni |
  LCodeEnd |
  LExecCmd |
  LContent |
  LSkip
    deriving(Eq)

data Token =
  CodeIni String AlexPosn String Bool |
  Include String AlexPosn |
  CodeEnd String AlexPosn |
  ExecCmd String AlexPosn |
  Content String AlexPosn |
  EOF
    deriving(Eq)

alexEOF :: Alex Token
alexEOF = return EOF

runAlex' :: Alex a -> String -> Either String a
runAlex' a input = runAlex input a

xxxN' :: ([a] ->[a]) ->[a] -> Int -> Int -> [a]
xxxN' f a b c
  | b == c = a
  | otherwise = xxxN' f (f a) (b+1) c

tailN :: [a] -> Int -> [a]
tailN a b = xxxN' tail a 0 b

initN :: [a] -> Int -> [a]
initN a b = xxxN' init a 0 b

tokErr :: Token -> String -> String
tokErr x a = showTokPos x ++ " -> " ++ a
}
