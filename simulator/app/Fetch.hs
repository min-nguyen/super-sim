module Fetch where

import Lib
import Data.Word
import Data.Bits
import Utils
import Control.Applicative
import qualified Data.Vector as V
import Debug.Trace


-- updateFetch :: CPU -> CPU
-- updateFetch cpu = 
--     let fUnit = case status (decodeUnit cpu) of 
--                 Ready ->  (fetchUnit cpu) { buffer = Just (i_memory cpu V.! (fromIntegral $ pc cpu)),
--                                             cycles = 1, status = Stalled }
                         
--                 Stalled -> fetchUnit cpu 
--     in  cpu { fetchUnit = tick fUnit (decodeUnit cpu) } 

updateFetch :: CPU -> CPU
updateFetch cpu = 
        if fetchN == 0 || freeBufferSpace == 0
        then trace "FetchUnit buffer full or all instructions fetched " (cpu { fetchUnit = tick (fetchUnit cpu) } )
        else trace ("Fetching " ++ show fetchN ++ " new instructions: ")  (
                    let fUnit = (fetchUnit cpu) {   buffer = buff V.++ (V.slice current_pc fetchN (i_memory cpu)), 
                                                    cycles = 1 }
                        idOrFlush = trace (show $ buffer fUnit)  (if npc cpu == pc cpu  then id else flushPipeline)

                    in  idOrFlush $ cpu { fetchUnit = tick fUnit , 
                                          pc =  if npc cpu == pc cpu then (fromIntegral $ current_pc + fetchN) else npc cpu, 
                                          npc = if npc cpu == pc cpu then (fromIntegral $ current_pc + fetchN) else npc cpu} )

        where fetchN = if freeBufferSpace > endlen 
                       then endlen
                       else freeBufferSpace
              freeBufferSpace = 4 - V.length buff
              endlen = (V.length (i_memory cpu) - current_pc)
              current_pc = (fromIntegral $ pc cpu)
              buff = buffer (fetchUnit cpu)