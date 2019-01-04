{-# OPTIONS_GHC -fno-warn-orphans #-}

module Main (main) where

import           Control.DeepSeq
import           Control.Monad
import           Criterion.Main
import           Criterion.Types
import           Data.ByteString          (ByteString)
import qualified Data.ByteString.Lazy     as L
import qualified Data.Csv
import qualified Data.CSV.Conduit
import qualified Data.Sv
import qualified Data.Sv.Decode
import           Data.Vector              (Vector)
import           System.Directory
import qualified Text.CSV
import qualified Text.CSV.Lazy.ByteString
import qualified Text.Parsec.Error

main :: IO ()
main = do
  let fp = "out.csv"
  exists <- doesFileExist fp
  when exists (removeFile fp)
  defaultMainWith
    defaultConfig {csvFile = Just fp}
    [ bgroup
        "file (time)"
        [ bench
            "cassava/decode/Vector ByteString"
            (nfIO
               (do r <-
                     fmap (Data.Csv.decode Data.Csv.HasHeader) (L.readFile infp) :: IO (Either String (Vector (Vector ByteString)))
                   case r of
                     Left _  -> error "Unexpected parse error"
                     Right v -> pure v))
        , bench
            "cassava/decode/[ByteString]"
            (nfIO
               (do r <-
                     fmap (Data.Csv.decode Data.Csv.HasHeader) (L.readFile infp) :: IO (Either String (Vector [ByteString]))
                   case r of
                     Left _  -> error "Unexpected parse error"
                     Right v -> pure v))
        , bench
            "lazy-csv/parseCsv/[ByteString]"
            (nfIO
                (do r <- fmap Text.CSV.Lazy.ByteString.parseCSV (L.readFile infp)
                    pure $ Text.CSV.Lazy.ByteString.fromCSVTable $ Text.CSV.Lazy.ByteString.csvTableFull r))
        , bench
            "csv-conduit/readCSVFile/[ByteString]"
            (nfIO
               (Data.CSV.Conduit.readCSVFile
                  Data.CSV.Conduit.defCSVSettings
                  infp :: IO (Vector [ByteString])))
        , bench
            "csv-conduit/readCSVFile/Vector ByteString"
            (nfIO
               (Data.CSV.Conduit.readCSVFile
                  Data.CSV.Conduit.defCSVSettings
                  infp :: IO (Vector (Vector ByteString))))
        , bench
            "csv-conduit/readCSVFile/[String]"
            (nfIO
               (Data.CSV.Conduit.readCSVFile
                  Data.CSV.Conduit.defCSVSettings
                  infp :: IO (Vector [String])))
        , bench
            "csv/Text.CSV/parseCSVFromFile"
            (nfIO (Text.CSV.parseCSVFromFile infp))
        , bench
            "sv/Data.Sv/parseDecodeFromFile"
            (nfIO
               (Data.Sv.parseDecodeFromFile
                  Data.Sv.Decode.row
                  Data.Sv.defaultParseOptions
                  infp))
        ]
    ]

-- | We don't need to force error messages, the test suite only parses
-- valid CSV files.
instance NFData Text.Parsec.Error.ParseError where
  rnf _ = error "Unexpected parse error."

infp :: FilePath
infp = "in.csv"
