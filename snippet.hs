module MdrSnip
  ( snippet
  , findSnipk'
  , Snippet
  ) where

import           MdrLexr
import           MdrUtil

type Snippet = (String, IO String)

data Snip = Snip
  { knowTok     :: [[Token]]
  , knowVisited :: [String]
  , knowResult  :: [Snippet]
  , knowCurr    :: Snippet
  }

isInclude :: String -> String -> Bool
isInclude a b = "@[[" ++ a ++ "]]" == b

snipExist' :: [Token] -> (String -> Bool)
snipExist' x = isInclude (stmtId x)

snipExist :: [[Token]] -> String -> Bool
snipExist [] _     = False
snipExist [x] s    = snipExist' x s
snipExist (x:xs) s = snipExist' x s || snipExist xs s

snipRecurs :: [String] -> String -> Bool
snipRecurs [] _     = False
snipRecurs [x] s    = isInclude x s
snipRecurs (x:xs) s = isInclude x s || snipRecurs xs s

findSnip :: [[Token]] -> Token -> [Token]
findSnip [] _ = []
findSnip [x] y
  | isInclude (stmtId x) (tokStr y) = tail x
  | otherwise = []
findSnip (x:xs) y
  | isInclude (stmtId x) (tokStr y) = x
  | otherwise = findSnip xs y

patternNotFound :: String -> MdrString
patternNotFound a = Left $ "'" ++ a ++ "' -> pattern not found"

findSnipk' :: [Snippet] -> String -> MdrString
findSnipk' [] a = patternNotFound a
findSnipk' [(a, b)] y
  | isInclude a y = Right b
  | otherwise = patternNotFound a
findSnipk' ((a, b):xs) y
  | isInclude a y = Right b
  | otherwise = findSnipk' xs y

doExpand :: Snip -> Token -> MdrString
doExpand k x =
  case b of
    Right nk ->
      case findSnipk' (knowResult nk) (tokStr x) of
        Right a -> Right a
        Left e  -> Left $ tokErr x e
    Left e -> Left e
  where
    b =
      snipStmt'
        (Snip
           tok
           (vis ++ [tokId x])
           ret
           (tailN (initN (tokStr x) 2) 3, return []))
        (findSnip (knowTok k) x)
    tok = knowTok k
    vis = knowVisited k
    ret = knowResult k

doInclude' :: Snip -> [Snippet] -> Token -> MdrString
doInclude' _ [] _ = Right $ return []
doInclude' k [(a, b)] y =
  if isInclude a (tokStr y)
    then Right b
    else case c of
           Right nk -> doExpand nk y
           Left e   -> Left e
  where
    c = snipStmt' k (findSnip (knowTok k) y)
doInclude' k ((a, b):xs) y
  | isInclude a (tokStr y) = Right b
  | otherwise = doInclude' k xs y

doInclude :: Snip -> Token -> Either String Snip
doInclude k x =
  case doInclude' k (knowResult k) x of
    Right s -> Right $ newSnipToken k s
    Left e  -> Left e

knowIncludek :: Snip -> Token -> Either String Snip
knowIncludek k x
  | not (snipRecurs (knowVisited k) (tokStr x)) = doInclude k x
  | otherwise = Left "Recursive include"

newSnipToken :: Snip -> IO String -> Snip
newSnipToken a b = Snip tok vis ret (key, addM str b)
  where
    tok = knowTok a
    vis = knowVisited a
    ret = knowResult a
    (key, str) = knowCurr a

snipToken :: Snip -> Token -> Either String Snip
snipToken k (Include a b) =
  if snipExist (knowTok k) a
    then knowIncludek k (Include a b)
    else Left $ "Snippet Does not exist: '" ++ initN (tailN a 3) 2 ++ "'" -- TODO pos
snipToken k (ExecCmd a _) = Right $ newSnipToken k (execcmd a)
snipToken k x = Right $ newSnipToken k (return $ tokStr x)

addRet :: [Snippet] -> Snippet -> [Snippet]
addRet a (b, c) = a ++ [(b, c)]

snipStmt' :: Snip -> [Token] -> Either String Snip
snipStmt' k [] = Right k
snipStmt' k [x] =
  case snipToken k x of
    Right nk ->
      Right $ Snip tok vis (addRet ret (a, fmap init b)) ([], return [])
      where tok = knowTok nk
            vis = knowVisited nk
            ret = knowResult nk
            (a, b) = knowCurr nk
    Left e -> Left e
snipStmt' k (x:xs) =
  case snipToken k x of
    Right nk -> snipStmt' nk xs
    Left e   -> Left e

snipStmt :: Snip -> [Token] -> Either String Snip
snipStmt k x = snipStmt' (Snip tok vis ret (stmtId x, return [])) (tail x)
  where
    tok = knowTok k
    vis = knowVisited k
    ret = knowResult k

snipAst' :: Snip -> [[Token]] -> Either String Snip
snipAst' k [] = Right k
snipAst' k [x] = snipStmt k x
snipAst' k (x:xs) =
  case snipStmt k x of
    Right nk -> snipAst' nk xs
    Left e   -> Left e

newSnipStmt :: [[Token]] -> [Token] -> Snip
newSnipStmt a x = Snip a [stmtId x] [] (stmtId x, return [])

snipAst :: [[Token]] -> [[Token]] -> Either String Snip
snipAst a [] = Right $ Snip a [] [] ([], return [])
snipAst a [x] = snipStmt' (newSnipStmt a x) (tail x)
snipAst a (x:xs) =
  case snipStmt' (newSnipStmt a x) (tail x) of
    Right k -> snipAst' k xs
    Left e  -> Left e

snippet :: [[Token]] -> Either String [Snippet]
snippet [] = Right []
snippet x =
  let y = sortCodes stmtSnip x
   in case snipAst y y of
        Right a -> Right $ knowResult a
        Left e  -> Left e
