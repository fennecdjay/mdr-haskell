module MdrView
  ( view
  ) where

import           MdrCode (codeStmt)
import           MdrLexr (Token (ExecCmd), stmtFile, stmtSnip, tokStr)
import           MdrSnip (Snippet)
import           MdrUtil

viewToken :: Token -> IO String
viewToken (ExecCmd a _) = return $! "@exec " ++ a
viewToken x             = return $! tokStr x

viewStmt' :: [Token] -> IO String
viewStmt' = foldr (addM . viewToken) (return [])

viewStmt :: [Snippet] -> [Token] -> MdrString
viewStmt s x
  | stmtSnip x || stmtFile x = Right $ addM (viewStmt' x) (return "```")
  | otherwise = codeStmt s x

viewAst :: [Snippet] -> [[Token]] -> MdrString
viewAst _ [] = Right $ return []
viewAst s (x:xs) =
  case viewStmt s x of
    Right a ->
      case viewAst s xs of
        Right b -> Right $ addM a b
        Left e  -> Left e
    Left e -> Left e

view :: FilePath -> [Snippet] -> [[Token]] -> IO (Either IOError ())
view fp s x =
  case viewAst s x of
    Right a -> mdrUsrOk view' fp a
    Left e  -> mdrUsrErr e

view' :: FilePath -> String -> IO (Either IOError ())
view' fp c
  | fp == "stdin" = putStrLn c >> return (Right ())
  | otherwise = writeGivenFile fp c
