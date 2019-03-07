{-# LANGUAGE LambdaCase #-}

module MdrCode
  ( code
  , codeStmt
  ) where

import           Control.Exception
import           GHC.IO.Exception  (IOException (..))
import           MdrLexr
import           MdrSnip           (Snippet, findSnipk')
import           MdrUtil

codeToken :: [Snippet] -> Token -> MdrString
codeToken s (Include a _) = findSnipk' s a
codeToken _ (ExecCmd a _) = Right $ execcmd a >>= evaluate
codeToken _ x             = Right $ return $ tokStr x

codeStmt' :: IO String -> [Snippet] -> [Token] -> MdrString
codeStmt' t s xs =
  case codeStmt s xs of
    Right u -> Right $ addM t u
    Left e  -> Left $ tokErr (head xs) e

codeStmt :: [Snippet] -> [Token] -> MdrString
codeStmt _ [] = Right $ return []
codeStmt s [x] =
  case codeToken s x of
    Right a -> Right a
    Left e  -> Left $ tokErr x e
codeStmt s (x:xs) =
  case codeToken s x of
    Right t -> codeStmt' t s xs
    Left e  -> Left e

code2file :: [Snippet] -> [Token] -> IO (Either IOError ())
code2file s a =
  case codeStmt s (tail a) of
    Right b -> mdrUsrOk writeGivenFile (stmtId a) b
    Left e  -> mdrUsrErr (tokErr (head $ tail a) e)

codeAst :: [Snippet] -> [[Token]] -> IO (Either IOError ())
codeAst _ [] = return $ pure ()
codeAst s [x] = code2file s x
codeAst s (x:xs) =
  code2file s x >>= \case
    Right _ -> codeAst s xs
    Left e ->
      mdrUsrErr
        (tokErr (head x) (ioe_description e) ++
         "\n... while trying to write " ++ bold (stmtId x))

code :: [[Token]] -> [Snippet] -> IO (Either IOError ())
code a b = codeAst b (sortCodes stmtFile a)
