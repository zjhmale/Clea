module Main where

import Scope
import Eval (eval)
import Ast (Env, SExpr(..), mkFunc)
import Parser (parseExpr)
import Prologue (builtins, loadlib)
import Control.Lens
import Control.Monad.Trans
import System.Environment
import System.Console.Haskeline
import Data.List (intercalate)
import qualified Data.Map as M
import qualified Data.Set as S
import qualified Control.Exception as E

process :: Env -> String -> IO ()
process scope expr = E.catch (do
                              let ast = parseExpr expr
                              result <- eval ast scope
                              putStrLn $ show result)
                             (\(E.ErrorCall e) -> do
                              putStrLn e)

loop :: Env -> InputT IO ()
loop scope = do
  minput <- getInputLine "λ> "
  case minput of
    Nothing -> do
      outputStrLn "Goodbye."
    Just input -> (liftIO $ process scope input) >> (loop scope)

prologueMessage :: String
prologueMessage = intercalate "\n"
  ["   ___  __    ____   __",
   "  / __)(  )  (  __) / _\\",
   " ( (__ / (_/\\ ) _) /    \\",
   "  \\___)\\____/(____)\\_/\\_/",
   ""
   ]

main :: IO ()
main = do
  args <- getArgs
  scope <- emptyScope
  mapM_ (\(k, v) -> (insertValue scope (ESymbol k) v)) builtins
  loadlib scope
  insertValue scope (ESymbol "eval") (mkFunc (\[ast] -> eval ast scope))
  case (args ^? element 0) of
    Just arg -> if arg == "repl"
               then do
                putStrLn prologueMessage
                runInputT defaultSettings (loop scope)
               else process scope $ "(load-file \"" ++ arg ++ "\")"
    Nothing -> do
      input <- getContents
      process scope input
