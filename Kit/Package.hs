module Kit.Package (package) where

  import Kit.Model
  import Kit.Util
  import Kit.Project
  import System.Cmd
  import Control.Monad.Trans
  import Control.Monad
  import Data.List
  import Data.Maybe
  import Debug.Trace

  {-
    Package format
     src/ | configurable source dir
     test/ | test directory
     lib/ | lib directory
     *.xcconfig
     *.pch
     KitSpec
     *.codeproj
  -}

  fileBelongsInPackage :: KitSpec -> FilePath -> Bool
  fileBelongsInPackage config fp = let
    a = elem fp [specSourceDirectory config, specTestDirectory config, specLibDirectory config, "KitSpec"]
    b = "xcodeproj" `isSuffixOf` fp
    c = "xcconfig" `isSuffixOf` fp
    d = ".pch" `isSuffixOf` fp
      in a || b || c || d

  package :: KitSpec -> IO ()
  package spec = do
      tempDir <- getTemporaryDirectory
      current <- getCurrentDirectory
      distDir <- fmap (</> "dist") getCurrentDirectory
      let kd = tempDir </> kitPath
      cleanOrCreate kd
      contents <- getDirectoryContents "."
      mapM_ (cp_r_to kd) (filter (fileBelongsInPackage spec) contents)
      mkdir_p distDir
      inDirectory tempDir $ sh $ "tar czf " ++ (distDir </> (kitPath ++ ".tar.gz")) ++ " " ++ kitPath
      return ()
    where
      kitPath = packageFileName spec
      sh c = liftIO $ system (trace c c)
      puts c = liftIO $ putStrLn c
      p c = liftIO $ print c
      cp_r_to kd c = sh $ "cp -r " ++ c ++ " " ++ kd ++ "/"


