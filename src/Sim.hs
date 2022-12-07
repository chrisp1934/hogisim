module Sim where

import Data.Either
import Data.List
import Data.Matrix as M

import qualified Bool as B
import Model.Cell as C
import qualified Types as T


type NodeError = ((Int, Int), String)
type UnaryFunc = Bool -> Bool
type BinaryFunc = Bool -> Bool -> Bool


disconnectErrorMsg = "Disconnect error"
cycleDetectedErrorMsg = "Cycle"
multipleInputsError = "Multiple inputs"
invalidCellError = "Invalid cell"


data Node
    = Input Bool
    | Direct UnaryFunc Node
    | Gate BinaryFunc Node Node


solve :: Node -> Bool
solve (Input b) = b
solve (Direct f n) = f (solve n)
solve (Gate f n1 n2) = f (solve n1) (solve n2)


data RecursionData = RD
  { visited :: [T.Coordinate]
  , fromDir :: Dir
  }


data Dir
    = DirUp
    | DirRight
    | DirDown
    | DirLeft
    | DirNone
    deriving (Eq)


andGates =
    [ C.HorizontalAND
    , C.HorizontalANDInputLR
    , C.HorizontalANDInputRL
    , C.HorizontalANDOutputLR
    , C.HorizontalANDOutputRL
    ]

orGates =
    [ C.HorizontalOR
    , C.HorizontalORInputLR
    , C.HorizontalORInputRL
    , C.HorizontalOROutputLR
    , C.HorizontalOROutputRL
    ]

xorGates =
    [ C.HorizontalXOR
    , C.HorizontalXORInputLR
    , C.HorizontalXORInputRL
    , C.HorizontalXOROutputLR
    , C.HorizontalXOROutputRL
    ]

norGates =
    [ C.HorizontalNOR
    , C.HorizontalNORInputLR
    , C.HorizontalNORInputRL
    , C.HorizontalNOROutputLR
    , C.HorizontalNOROutputRL
    ]

nandGates =
    [ C.HorizontalNAND
    , C.HorizontalNANDInputLR
    , C.HorizontalNANDInputRL
    , C.HorizontalNANDOutputLR
    , C.HorizontalNANDOutputRL
    ]

xnorGates =
    [ C.HorizontalXNOR
    , C.HorizontalXNORInputLR
    , C.HorizontalXNORInputRL
    , C.HorizontalXNOROutputLR
    , C.HorizontalXNOROutputRL
    ]


transform :: M.Matrix C.Cell -> [Either NodeError Node]
transform m = [transformCell outputCell m (RD [] DirNone) | outputCell <- outputCells]
    where outputCells = [m ! (x, y) | x <- [0..T.boardSize], y <- [0..T.boardSize], getContent (m ! (x, y)) == C.UnknownOutput]


transformCell :: C.Cell -> M.Matrix C.Cell -> RecursionData -> Either NodeError Node
transformCell (C.C C.LowSource _) = transformInput False
transformCell (C.C C.HighSource _) = transformInput True
transformCell (C.C C.UnknownOutput coord) = transformOutput coord
transformCell (C.C C.HorizontalPath coord) = transformPath [DirLeft, DirRight] coord
transformCell (C.C C.VerticalPath coord) = transformPath [DirUp, DirDown] coord
transformCell (C.C C.PathCross coord) = transformCross coord
transformCell (C.C C.PathIntersection coord) = transformPath [DirUp, DirRight, DirDown, DirLeft] coord
transformCell (C.C C.VerticalRightPath coord) = transformPath [DirUp, DirRight, DirDown] coord
transformCell (C.C C.VerticalLeftPath coord) = transformPath [DirUp, DirLeft, DirDown] coord
transformCell (C.C C.HorizontalUpPath coord) = transformPath [DirUp, DirRight, DirLeft] coord
transformCell (C.C C.HorizontalDownPath coord) = transformPath [DirRight, DirDown, DirLeft] coord
transformCell (C.C C.QuadrantThreePath coord) = transformPath [DirDown, DirLeft] coord
transformCell (C.C C.QuadrantTwoPath coord) = transformPath [DirUp, DirLeft] coord
transformCell (C.C C.QuadrantFourPath coord) = transformPath [DirRight, DirDown] coord
transformCell (C.C C.QuadrantOnePath coord) = transformPath [DirUp, DirRight] coord
transformCell (C.C C.HorizontalBufferLR coord) = transformUnaryGate DirRight id coord
transformCell (C.C C.HorizontalBufferRL coord) = transformUnaryGate DirLeft id coord
transformCell (C.C C.HorizontalInverterLR coord) = transformUnaryGate DirRight not coord
transformCell (C.C C.HorizontalInverterRL coord) = transformUnaryGate DirLeft not coord
transformCell (C.C C.HorizontalORInputLR coord) = transformGateInput DirLeft (||) orGates coord
transformCell (C.C C.HorizontalORInputRL coord) = transformGateInput DirRight (||) orGates coord
transformCell (C.C C.HorizontalOROutputLR coord) = transformGateOutput DirRight (||) orGates coord
transformCell (C.C C.HorizontalOROutputRL coord) = transformGateOutput DirLeft (||) orGates coord
transformCell (C.C C.HorizontalOR coord) = transformGateBody orGates coord
transformCell (C.C C.HorizontalANDInputLR coord) = transformGateInput DirLeft (&&) andGates coord
transformCell (C.C C.HorizontalANDInputRL coord) = transformGateInput DirRight (&&) andGates coord
transformCell (C.C C.HorizontalANDOutputLR coord) = transformGateOutput DirRight (&&) andGates coord
transformCell (C.C C.HorizontalANDOutputRL coord) = transformGateOutput DirLeft (&&) andGates coord
transformCell (C.C C.HorizontalAND coord) = transformGateBody andGates coord
transformCell (C.C C.HorizontalXORInputLR coord) = transformGateInput DirLeft B.xor xorGates coord
transformCell (C.C C.HorizontalXORInputRL coord) = transformGateInput DirRight B.xor xorGates coord
transformCell (C.C C.HorizontalXOROutputLR coord) = transformGateOutput DirRight B.xor xorGates coord
transformCell (C.C C.HorizontalXOROutputRL coord) = transformGateOutput DirLeft B.xor xorGates coord
transformCell (C.C C.HorizontalXOR coord) = transformGateBody xorGates coord
transformCell (C.C C.HorizontalNORInputLR coord) = transformGateInput DirLeft B.nor norGates coord
transformCell (C.C C.HorizontalNORInputRL coord) = transformGateInput DirRight B.nor norGates coord
transformCell (C.C C.HorizontalNOROutputLR coord) = transformGateOutput DirRight B.nor norGates coord
transformCell (C.C C.HorizontalNOROutputRL coord) = transformGateOutput DirLeft B.nor norGates coord
transformCell (C.C C.HorizontalNOR coord) = transformGateBody norGates coord
transformCell (C.C C.HorizontalNANDInputLR coord) = transformGateInput DirLeft B.nand nandGates coord
transformCell (C.C C.HorizontalNANDInputRL coord) = transformGateInput DirRight B.nand nandGates coord
transformCell (C.C C.HorizontalNANDOutputLR coord) = transformGateOutput DirRight B.nand nandGates coord
transformCell (C.C C.HorizontalNANDOutputRL coord) = transformGateOutput DirLeft B.nand nandGates coord
transformCell (C.C C.HorizontalNAND coord) = transformGateBody nandGates coord
transformCell (C.C C.HorizontalXNORInputLR coord) = transformGateInput DirLeft B.xnor xnorGates coord
transformCell (C.C C.HorizontalXNORInputRL coord) = transformGateInput DirRight B.xnor xnorGates coord
transformCell (C.C C.HorizontalXNOROutputLR coord) = transformGateOutput DirRight B.xnor xnorGates coord
transformCell (C.C C.HorizontalXNOROutputRL coord) = transformGateOutput DirLeft B.xnor xnorGates coord
transformCell (C.C C.HorizontalXNOR coord) = transformGateBody xnorGates coord
transformCell (C.C _ coord) = transformInvalid coord


transformInvalid :: T.Coordinate -> M.Matrix C.Cell -> RecursionData -> Either NodeError Node
transformInvalid coord _ _ = Left (coord, invalidCellError)

transformInput :: Bool -> M.Matrix C.Cell -> RecursionData -> Either NodeError Node
transformInput b _ _ = return (Input b)

transformOutput :: T.Coordinate -> M.Matrix C.Cell -> RecursionData -> Either NodeError Node
transformOutput coord m rd
    | fromDir rd == DirNone = transformPath [DirUp, DirRight, DirDown, DirLeft, DirNone] coord m rd
    | otherwise = transformPath [DirUp, DirRight, DirDown, DirLeft] coord m rd

transformPath :: [Dir] -> T.Coordinate -> M.Matrix C.Cell -> RecursionData -> Either NodeError Node
transformPath allowedDirs coord m rd
    | coord `elem` visited rd = Left (coord, cycleDetectedErrorMsg)
    | fromDir rd `notElem` allowedDirs = Left (coord, disconnectErrorMsg)
    | otherwise = do
        if numValidNodes == 0
            then head depNodes
        else if numValidNodes > 1
            then Left (coord, multipleInputsError)
        else head (filter isRight depNodes)
        where
            v = coord:visited rd
            depDirs = delete (fromDir rd) allowedDirs
            depNodes = [transformCell (m ! (coord `moveTo` depDir)) m (RD v (flipDir depDir)) | depDir <- depDirs]
            numValidNodes = (length . filter isRight) depNodes

transformCross :: T.Coordinate -> M.Matrix C.Cell -> RecursionData -> Either NodeError Node
transformCross coord m rd
    | coord `elem` visited rd = Left (coord, cycleDetectedErrorMsg)
    | otherwise = transformCell depCell m (RD v (fromDir rd))
    where
        depCell = m ! (coord `moveAway` fromDir rd)
        v = coord:visited rd

transformUnaryGate :: Dir -> UnaryFunc -> T.Coordinate -> M.Matrix C.Cell -> RecursionData -> Either NodeError Node
transformUnaryGate outputDir f coord m rd
    | fromDir rd /= outputDir = Left (coord, disconnectErrorMsg)
    | otherwise = do
        depNode <- transformCell (m ! (coord `moveAway` fromDir rd)) m (RD v (fromDir rd))
        return (Direct f depNode)
        where
            v = coord:visited rd

transformGateBody :: [C.CellContent] -> T.Coordinate -> M.Matrix C.Cell -> RecursionData -> Either NodeError Node
transformGateBody gates coord m rd
    | fromDir rd == DirLeft || fromDir rd == DirRight = Left (coord, disconnectErrorMsg)
    | otherwise = do
        if getContent depCell `elem` gates then transformCell depCell m (RD v (fromDir rd))
        else Left (coord, disconnectErrorMsg)
        where
            depCell = m ! (coord `moveAway` fromDir rd)
            v = coord:visited rd

transformGateInput :: Dir -> BinaryFunc -> [C.CellContent] -> T.Coordinate -> M.Matrix C.Cell -> RecursionData -> Either NodeError Node
transformGateInput inputDir f gates coord m rd
    | fromDir rd == DirLeft || fromDir rd == DirRight = Left (coord, disconnectErrorMsg)
    | otherwise = do
        inputNode <- transformCell (m ! (coord `moveTo` inputDir)) m (RD v (flipDir inputDir))
        if getContent depCell `elem` gates then do
            prevNode <- transformCell depCell m (RD v (fromDir rd))
            return (Gate f inputNode prevNode)
        else return (Direct id inputNode)
        where
            depCell = m ! (coord `moveAway` fromDir rd)
            v = coord:visited rd

transformGateOutput :: Dir -> BinaryFunc -> [C.CellContent] -> T.Coordinate -> M.Matrix C.Cell -> RecursionData -> Either NodeError Node
transformGateOutput outputDir f gates coord m rd
    | fromDir rd /= outputDir = Left (coord, disconnectErrorMsg)
    | otherwise = do
        if upHasGate && downHasGate then do
            depNodeUp <- transformCell depCellUp m (RD v DirDown)
            depNodeDown <- transformCell depCellDown m (RD v DirUp)
            return (Gate f depNodeUp depNodeDown)
        else if upHasGate then transformCell depCellUp m (RD v DirDown)
        else if downHasGate then  transformCell depCellDown m (RD v DirUp)
        else Left (coord, disconnectErrorMsg)
        where
            depCellUp = m ! (coord `moveTo` DirUp)
            depCellDown = m ! (coord `moveTo` DirDown)
            upHasGate = getContent depCellUp `elem` gates
            downHasGate = getContent depCellDown `elem` gates
            v = coord:visited rd


moveTo :: T.Coordinate -> Dir -> T.Coordinate
moveTo (x, y) DirUp = (x, y + 1)
moveTo (x, y) DirRight = (x + 1, y)
moveTo (x, y) DirDown = (x, y - 1)
moveTo (x, y) DirLeft = (x - 1, y)
moveTo (x, y) DirNone = (x, y)


moveAway :: T.Coordinate -> Dir -> T.Coordinate
moveAway (x, y) DirUp = (x, y - 1)
moveAway (x, y) DirRight = (x - 1, y)
moveAway (x, y) DirDown = (x, y + 1)
moveAway (x, y) DirLeft = (x + 1, y)
moveAway (x, y) DirNone = (x, y)


flipDir :: Dir -> Dir
flipDir DirUp = DirDown
flipDir DirRight = DirLeft
flipDir DirDown = DirUp
flipDir DirLeft = DirRight
flipDir DirNone = DirNone