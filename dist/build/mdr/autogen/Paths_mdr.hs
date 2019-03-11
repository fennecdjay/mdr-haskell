{-# LANGUAGE CPP #-}
{-# LANGUAGE NoRebindableSyntax #-}
{-# OPTIONS_GHC -fno-warn-missing-import-lists #-}
module Paths_mdr (
    version,
    getBinDir, getLibDir, getDynLibDir, getDataDir, getLibexecDir,
    getDataFileName, getSysconfDir
  ) where

import qualified Control.Exception as Exception
import Data.Version (Version(..))
import System.Environment (getEnv)
import Prelude

#if defined(VERSION_base)

#if MIN_VERSION_base(4,0,0)
catchIO :: IO a -> (Exception.IOException -> IO a) -> IO a
#else
catchIO :: IO a -> (Exception.Exception -> IO a) -> IO a
#endif

#else
catchIO :: IO a -> (Exception.IOException -> IO a) -> IO a
#endif
catchIO = Exception.catch

version :: Version
version = Version [0,1,0,0] []
bindir, libdir, dynlibdir, datadir, libexecdir, sysconfdir :: FilePath

bindir     = "/home/djay/.cabal/bin"
libdir     = "/home/djay/.cabal/lib/x86_64-linux-ghc-8.6.3/mdr-0.1.0.0-IgvRHVnpzinJVsqm0ttIey-mdr"
dynlibdir  = "/home/djay/.cabal/lib/x86_64-linux-ghc-8.6.3"
datadir    = "/home/djay/.cabal/share/x86_64-linux-ghc-8.6.3/mdr-0.1.0.0"
libexecdir = "/home/djay/.cabal/libexec/x86_64-linux-ghc-8.6.3/mdr-0.1.0.0"
sysconfdir = "/home/djay/.cabal/etc"

getBinDir, getLibDir, getDynLibDir, getDataDir, getLibexecDir, getSysconfDir :: IO FilePath
getBinDir = catchIO (getEnv "mdr_bindir") (\_ -> return bindir)
getLibDir = catchIO (getEnv "mdr_libdir") (\_ -> return libdir)
getDynLibDir = catchIO (getEnv "mdr_dynlibdir") (\_ -> return dynlibdir)
getDataDir = catchIO (getEnv "mdr_datadir") (\_ -> return datadir)
getLibexecDir = catchIO (getEnv "mdr_libexecdir") (\_ -> return libexecdir)
getSysconfDir = catchIO (getEnv "mdr_sysconfdir") (\_ -> return sysconfdir)

getDataFileName :: FilePath -> IO FilePath
getDataFileName name = do
  dir <- getDataDir
  return (dir ++ "/" ++ name)
