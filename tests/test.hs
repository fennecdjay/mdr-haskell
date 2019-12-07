import System.Exit (ExitCode(ExitSuccess))
import System.Process (system)

--build = "./dist/build/mdr/"
--cmd = build ++ "mdr "
cmd = "~/.cabal/bin/mdr "

main = do
    -- This dies with a pattern match failure if the shell command fails
    ExitSuccess <- system $ "echo '#Just a title' | " ++ cmd
    ExitSuccess <- system $ "echo 'some content' | " ++ cmd ++ "--"
    ExitSuccess <- system $ cmd ++ " tests/*.mdr"
    return ()
