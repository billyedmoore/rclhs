module Main (main) where

import Data.Char (toUpper)
import Foreign (Ptr)
import RclHs
  ( Publisher,
    publish,
    secondInNanoSecond,
    spin,
    withContext,
    withNode,
    withPublisher,
    withSubscription,
    withTimer,
  )
import System.Random (randomRIO)

-- YorkFacts were AI Generated, may consitute serious academic misconduct!
yorkFacts :: [String]
yorkFacts =
  [ "York was founded by the Romans in 71 AD as Eboracum.",
    "The city was the capital of the Roman province Britannia Inferior.",
    "Constantine the Great was proclaimed Roman Emperor in York in 306 AD.",
    "The Vikings captured the city in 866 AD and renamed it Jórvík.",
    "York Minster is one of the largest Gothic cathedrals in Northern Europe.",
    "The Shambles is often cited as the best-preserved medieval street in Europe.",
    "York's city walls are the longest town walls in England, stretching about 2 miles.",
    "The Great East Window of York Minster is the largest expanse of medieval stained glass in the world.",
    "York is widely considered the most haunted city in Europe, with over 500 recorded hauntings.",
    "The National Railway Museum in York is the largest of its kind in the world.",
    "Guy Fawkes, the man behind the Gunpowder Plot, was born in York in 1570.",
    "The city has been a major center for the confectionery industry, home to Rowntree's and Terry's.",
    "The Kit Kat was invented in York in 1935.",
    "Whippets were once known as 'the poor man’s racehorse' in the York area.",
    "Clifford's Tower is all that remains of York Castle, originally built by William the Conqueror.",
    "The River Ouse flows through the center of York and is prone to frequent flooding.",
    "York was the first city in the UK to have a 'cat trail' featuring statues of cats on buildings.",
    "The University of York was established in 1963 and is famous for its large duck population.",
    "York's Mansion House is the oldest purpose-built house for a Lord Mayor in England.",
    "The name 'York' evolved from Eboracum to Eoforwic to Jórvík to York.",
    "Richard III had a very strong connection to the city and is still celebrated there today.",
    "The Merchant Adventurers' Hall is one of the finest guildhalls in the world.",
    "Snickelways are the narrow pedestrian paths and lanes that crisscross the city.",
    "The shortest street in York has the longest name: Whip-Ma-Whop-Ma-Gate.",
    "York's Guildhall was largely destroyed by bombing in 1942 but has since been restored.",
    "The city hosts an annual Viking Festival, the largest of its kind in Europe.",
    "York Minster took about 250 years to build, from 1220 to 1472.",
    "The Roman column standing outside the Minster was found underneath the cathedral's foundations.",
    "York was once a major hub for the wool trade in the Middle Ages.",
    "The Terry's Chocolate Orange was produced in York until 2005.",
    "York has more miles of intact city walls than any other city in England.",
    "Stonegate is one of the oldest streets and follows the path of a Roman road.",
    "The 'York Realist' was an anonymous 15th-century author of the York Mystery Plays.",
    "Every four years, the city performs the York Mystery Plays in the streets on wagons.",
    "The Golden Fleece is often cited as York's most haunted pub.",
    "York was the primary northern seat of the Archbishops of Canterbury's rivals.",
    "The King's Manor was once the residence of the Abbot of St Mary's Abbey.",
    "St Mary's Abbey was once the richest and most powerful Benedictine monastery in the North.",
    "York’s railway station was the largest in the world when it opened in 1877.",
    "Dick Turpin, the famous highwayman, was imprisoned and executed in York.",
    "The city’s coat of arms features five lions on a red cross.",
    "York is a UNESCO City of Media Arts.",
    "The River Foss is the smaller of the two rivers meeting in the city.",
    "The Bar Convent is the oldest active Roman Catholic convent in England, founded in 1686.",
    "York’s Christmas Market is regularly voted one of the best in the UK.",
    "There are four main gateways into the city, known as 'Bars': Micklegate, Bootham, Monk, and Walmgate.",
    "The Roman Multangular Tower in the Museum Gardens has ten sides.",
    "York was the setting for the first ever meeting of the British Association for the Advancement of Science.",
    "The city has a long history of bells; Great Peter in the Minster weighs 10.8 tons.",
    "York is the only city in the UK where you can walk almost entirely around the center on elevated walls."
  ]

pubCallback :: Ptr Publisher -> [String] -> IO ()
pubCallback pub lst = do
  let lastIndex = length lst - 1
  randomIndex <- randomRIO (0, lastIndex)
  publish pub (lst !! randomIndex)

subCallback :: String -> IO ()
subCallback str = do
  putStrLn str
  putStrLn (map toUpper str)
  putStrLn $ take (length str - 1) str ++ "!!"
  putStrLn str

main :: IO ()
main = do
  putStrLn "Publishing CatFacts Every 5 Seconds!"
  withContext $ \ctx -> do
    withNode "hello" "" ctx $ \node -> do
      withPublisher "hello" node $ \pub -> do
        publish pub "Hello World!"
        withTimer ctx (pubCallback pub yorkFacts) (5 * secondInNanoSecond) $ \timer ->
          withSubscription "hello" node subCallback $ \sub ->
            spin ctx [sub] [timer]
