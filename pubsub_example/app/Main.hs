module Main where

import Foreign (Ptr)
import RclHs
  ( Publisher,
    publish,
    secondInNanoSecond,
    spinFor,
    withContext,
    withNode,
    withPublisher,
    withSubscription,
    withTimer,
  )
import RclHs.ExampleTypes.Msg.StringMessage

-- YorkFacts were AI Generated, may consitute serious academic misconduct!
yorkFacts :: [String]
yorkFacts =
  [ "0. York was founded by the Romans in 71 AD as Eboracum.",
    "1. The city was the capital of the Roman province Britannia Inferior.",
    "2. Constantine the Great was proclaimed Roman Emperor in York in 306 AD.",
    "3. The Vikings captured the city in 866 AD and renamed it Jórvík.",
    "4. York Minster is one of the largest Gothic cathedrals in Northern Europe.",
    "5. The Shambles is often cited as the best-preserved medieval street in Europe.",
    "6. York's city walls are the longest town walls in England, stretching about 2 miles.",
    "7. The Great East Window of York Minster is the largest expanse of medieval stained glass in the world.",
    "8. York is widely considered the most haunted city in Europe, with over 500 recorded hauntings.",
    "9. The National Railway Museum in York is the largest of its kind in the world.",
    "10. Guy Fawkes, the man behind the Gunpowder Plot, was born in York in 1570.",
    "11. The city has been a major center for the confectionery industry, home to Rowntree's and Terry's.",
    "12. The Kit Kat was invented in York in 1935.",
    "13. Whippets were once known as 'the poor man’s racehorse' in the York area.",
    "14. Clifford's Tower is all that remains of York Castle, originally built by William the Conqueror.",
    "15. The River Ouse flows through the center of York and is prone to frequent flooding.",
    "16. York was the first city in the UK to have a 'cat trail' featuring statues of cats on buildings.",
    "17. The University of York was established in 1963 and is famous for its large duck population.",
    "18. York's Mansion House is the oldest purpose-built house for a Lord Mayor in England.",
    "19. The name 'York' evolved from Eboracum to Eoforwic to Jórvík to York.",
    "20. Richard III had a very strong connection to the city and is still celebrated there today.",
    "21. The Merchant Adventurers' Hall is one of the finest guildhalls in the world.",
    "22. Snickelways are the narrow pedestrian paths and lanes that crisscross the city.",
    "23. The shortest street in York has the longest name: Whip-Ma-Whop-Ma-Gate.",
    "24. York's Guildhall was largely destroyed by bombing in 1942 but has since been restored.",
    "25. The city hosts an annual Viking Festival, the largest of its kind in Europe.",
    "26. York Minster took about 250 years to build, from 1220 to 1472.",
    "27. The Roman column standing outside the Minster was found underneath the cathedral's foundations.",
    "28. York was once a major hub for the wool trade in the Middle Ages.",
    "29. The Terry's Chocolate Orange was produced in York until 2005.",
    "30. York has more miles of intact city walls than any other city in England.",
    "31. Stonegate is one of the oldest streets and follows the path of a Roman road.",
    "32. The 'York Realist' was an anonymous 15th-century author of the York Mystery Plays.",
    "33. Every four years, the city performs the York Mystery Plays in the streets on wagons.",
    "34. The Golden Fleece is often cited as York's most haunted pub.",
    "35. York was the primary northern seat of the Archbishops of Canterbury's rivals.",
    "36. The King's Manor was once the residence of the Abbot of St Mary's Abbey.",
    "37. St Mary's Abbey was once the richest and most powerful Benedictine monastery in the North.",
    "38. York’s railway station was the largest in the world when it opened in 1877.",
    "39. Dick Turpin, the famous highwayman, was imprisoned and executed in York.",
    "40. The city’s coat of arms features five lions on a red cross.",
    "41. York is a UNESCO City of Media Arts.",
    "42. The River Foss is the smaller of the two rivers meeting in the city.",
    "43. The Bar Convent is the oldest active Roman Catholic convent in England, founded in 1686.",
    "44. York’s Christmas Market is regularly voted one of the best in the UK.",
    "45. There are four main gateways into the city, known as 'Bars': Micklegate, Bootham, Monk, and Walmgate.",
    "46. The Roman Multangular Tower in the Museum Gardens has ten sides.",
    "47. York was the setting for the first ever meeting of the British Association for the Advancement of Science.",
    "48. The city has a long history of bells; Great Peter in the Minster weighs 10.8 tons.",
    "49. York is the only city in the UK where you can walk almost entirely around the center on elevated walls."
  ]

pubCallback :: Ptr Publisher -> [String] -> Int -> IO Int
pubCallback pub facts i = do
  let index = (i + 1) `mod` length facts
  publish pub (StringMessage (facts !! index))
  return (i + 1)

subCallback :: () -> StringMessage -> IO ()
subCallback _ msg = putStrLn ("Recieved Fact - " ++ show (str msg))

main :: IO ()
main = do
  putStrLn "Publishing Every 5 Seconds!"
  let topic = "pubsub_example_topic"
  withContext $ \ctx -> do
    withNode "node_name" "" ctx $ \node -> do
      withPublisher @StringMessage topic node $ \pub -> do
        withTimer ctx (-1) (pubCallback pub yorkFacts) (5 * secondInNanoSecond) $ \timer ->
          withSubscription @StringMessage topic node () subCallback $ \sub -> do
            spinFor ctx [sub] [timer] (120 * secondInNanoSecond)
