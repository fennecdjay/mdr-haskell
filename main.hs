{-# LANGUAGE LambdaCase #-}

import           GHC.IO.Exception
import           MdrCode            (code)
import           MdrLexr            (Token, runAlex')
import           MdrPars            (mdr)
import           MdrSnip            (Snippet, snippet)
import           MdrUtil
import           MdrView
import           System.Environment (getArgs)
import           System.IO

runView ::
     Either IOException b
  -> String
  -> [Snippet]
  -> [[Token]]
  -> IO (Either IOError ())
runView e fp snip a =
  case e of
    Right _ -> view (init fp) snip a
    Left f  -> mdrUsrErr $ ioe_description f

viewMdrCheck :: FilePath -> Either IOException b -> IO ()
viewMdrCheck fp c =
  case c of
    Right _ -> return ()
    Left e -> errMdr (ioe_description e ++ "\n... while parsing " ++ bold fp)

runEnd :: [Snippet] -> String -> [[Token]] -> IO (Either IOError ())
runEnd snip fp a = code a snip >>= \b -> runView b fp snip a

runCode ::
     Either String [Snippet] -> String -> [[Token]] -> IO (Either IOError ())
runCode e fp a =
  case e of
    Right snip -> runEnd snip fp a
    Left s     -> mdrUsrErr s

runMdr :: FilePath -> String -> IO ()
runMdr fp content =
  case runAlex' mdr content of
    Right a -> runCode (snippet a) fp a >>= viewMdrCheck fp
    Left e  -> errMdr (e ++ "\n ... while parsing " ++ bold fp)

runFromStdIn :: IO ()
runFromStdIn = getContents >>= runMdr "stdin."

handleFile :: FilePath -> Handle -> IO ()
handleFile fp h = do
  hGetContents h >>= runMdr fp
  hClose h

handleArg :: FilePath -> IO ()
handleArg fp
  | fp == "--" = runFromStdIn
  | otherwise = openGivenFile fp ReadMode >>= \case
      Right f -> handleFile fp f
      Left e -> errMdr (bold fp ++ " -> " ++ ioe_description e)

handleArgs :: [String] -> IO ()
handleArgs []     = runFromStdIn
handleArgs [arg]  = handleArg arg
handleArgs (x:xs) = handleArg x >> handleArgs xs

main :: IO ()
main = getArgs >>= handleArgs
