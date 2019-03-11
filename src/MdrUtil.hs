module MdrUtil
  ( addM
  , sortCodes
  , stmtId
  , errMdr
  , writeGivenFile
  , openGivenFile
  , execcmd
  , bold
  , mdrUsrOk
  , mdrUsrErr
  , MdrString
  ) where

import           Control.Exception (catch)
import           Control.Monad     (join, liftM2)
import           MdrLexr           (Token, tokId)
import           System.IO
import           System.Process    (StdStream (CreatePipe), createProcess, proc,
                                    std_out)

type MdrString = Either String (IO String)

addM :: Monad m => m [a] -> m [a] -> m [a]
addM = liftM2 (++)

sortCodes' :: [[Token]] -> [[Token]]
sortCodes' [] = []
sortCodes' (x:xs) = concat (x : ret) : sortCodes' remain
  where
    name = tokId $ head x
    ret = map tail (filter (\y -> name == stmtId y) xs)
    remain = filter (\y -> name /= stmtId y) xs

sortCodes :: ([Token] -> Bool) -> [[Token]] -> [[Token]]
sortCodes f x = sortCodes' $ filter f x

stmtId :: [Token] -> String
stmtId x = tokId $ head x

errMdr :: String -> IO ()
errMdr a = putStrLn ("\ESC[31mMDR\ESC[0m: " ++ a)

bold :: String -> String
bold a = "'\ESC[1m" ++ a ++ "\ESC[0m'"

writeGivenFile :: FilePath -> String -> IO (Either IOError ())
writeGivenFile fp s = (Right <$> writeFile fp s) `catch` (return . Left)

openGivenFile :: String -> IOMode -> IO (Either IOError Handle)
openGivenFile fp s = (Right <$> openFile fp s) `catch` (return . Left)

execcmd :: String -> IO String
execcmd cmd =
  createProcess (proc "sh" ("-c" : [cmd])) {std_out = CreatePipe} >>= \(_, Just hout, _, _) ->
    hGetContents hout

mdrUsrErr :: Monad m => String -> m (Either IOError b)
mdrUsrErr a = return $ Left $ userError a

mdrUsrOk :: Monad m => (a1 -> a2 -> m a) -> a1 -> m a2 -> m a
mdrUsrOk f a b = join (liftM2 f (return a) b)
