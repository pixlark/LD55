local std = require "lib.std"

local Word = std.Object:extend()

function Word:new(word, separator)
    self.text = word
    self.separator = separator
end

function Word:text()
    return self.text..self.separator
end

local Chunk = std.Object:extend()

function Chunk:new(words)
    self.words = words
end

function Chunk:wordCount()
    return #self.words
end

local IndexedSpan = std.Object:extend()

function IndexedSpan:new(words, index)
    self.words = words
    self.index = index
end

function IndexedSpan:text()
    return std.iterate(self.words)
        :map(Word.text)
        :collectString()
end

function IndexedSpan:append(word)
    std.assertType(word, Word)

    local newWords = std.copy(self.words)
    table.insert(newWords, word)
    return IndexedSpan(newWords, self.index)
end

local WrappedLine = std.Object:extend()

function WrappedLine:new(spans)
    self.spans = spans
end

function WrappedLine:lastSpan()
    if #self.spans > 0 then
        return self.spans[#self.spans]
    else
        return nil
    end
end

function WrappedLine:fullText()
    return std.iterate(self.spans)
        :map(IndexedSpan.text)
        :collectString()
end

function WrappedLine:appendSpan(span)
    table.insert(self.spans, span)
end

function WrappedLine:copy()
    return WrappedLine(std.copy(self.spans))
end

local ConcreteSpan = std.Object:extend()

function ConcreteSpan:new(indexedSpan)
    self.text = indexedSpan:text()
    self.index = indexedSpan.index
end

local ConcreteLine = std.Object:extend()

function ConcreteLine:new(wrappedLine)
    self.spans = {}
    for spanIndex, span in ipairs(wrappedLine.spans) do
        -- Strip ending spaces from the line
        local strippedSpan
        if spanIndex == #wrappedLine.spans then
            strippedSpan = IndexedSpan(span.words, span.index)
            strippedSpan.words[#strippedSpan.words].separator = ""
        else
            strippedSpan = span
        end

        -- Strip beginning spaces from the line
        if not (spanIndex == 1 and span.text == "") then
            table.insert(self.spans, ConcreteSpan(strippedSpan))
        end
    end
end

local function splitIntoWords(str, seps)
    local function isSep(c)
        return seps:find(c, 1, true) ~= nil
    end

    local words = {}
    local accumulator
    local iterState = "start"

    local function endWord()
        if iterState == "word" then
            words[#words + 1] = Word(accumulator, "") -- { accumulator, "" }
        elseif iterState == "separator" then
            if #words == 0 then
                words[1] = Word("", "")
            end
            words[#words].separator = accumulator
        else
            assert(false)
        end
    end

    local function getNextState(char)
        if isSep(char) then
            return "separator"
        else
            return "word"
        end
    end

    for char in str:gmatch(".") do
        local nextState = getNextState(char)

        if iterState == "start" then
            accumulator = char
        elseif nextState ~= iterState then
            -- Word/separator boundary
            endWord()
            accumulator = char
        else
            accumulator = accumulator..char
        end

        iterState = nextState
    end

    endWord()

    return words
end

-- input: { "abcd ef ", "ghi-k lmnop." }
--
-- after chunking: {
--     Chunk { Word("abcd", " "), Word("ef", " ") },
--     Chunk { Word("ghi", "-"), Word("k", " "), Word("lmnop.", "") }
-- }
--
-- final wrapped output: {
--     WrappedLine {
--         IndexedSpan("abcd ef ", 1),
--         IndexedSpan("ghi-k", 2),
--     },
--     WrappedLine {
--         IndexedSpan("lmnop", 2),
--     },
-- }

local function wrapAnnotatedTextToLines(annotatedText, font, wrapWidth)
    -- Split every chunk of text into words, each of which consists of the
    -- word as well as the separator that follows it.

    -- We keep these separators around so that we can break on them if they
    -- stretch past the wrapWidth -- otherwise, they're inserted back into
    -- the text. This way, the wrapped text retains as much of the original
    -- formatting as possible.

    local chunks = std.iterate(annotatedText)
        :map(function (text) return Chunk(splitIntoWords(text, " \t-")) end)
        :collect()

    local totalWordCount = std.iterate(chunks)
        :map(Chunk.wordCount)
        :sum()

    local allWords = std.iterate(chunks)
        :map(function (chunk) return chunk.words end)
        :join()
        :collect()

    local function getChunkIndex(index)
        std.assertType(index, "number")

        for chunkIndex, chunk in ipairs(chunks) do
            if index <= chunk:wordCount() then
                return chunkIndex
            end

            index = index - chunk:wordCount()
        end

        std.unreachableException()
    end

    local finalWrappedLines = {}
    local accumulator

    -- Add a word to the accumulating line, possibly splitting to a new
    -- IndexedSpan if we cross a chunk boundary, and return it.
    local function addWord(word, chunkIndex)
        std.assertType(word, Word)
        std.assertType(chunkIndex, "number")

        local line = accumulator:copy()
        std.assertType(line, WrappedLine)

        local lastSpan = line:lastSpan()
        std.assertType(lastSpan, IndexedSpan)

        if chunkIndex == lastSpan.index then
            -- Our new word descends from the same original chunk, so just append it
            line.spans[#line.spans] = lastSpan:append(word)
        else
            -- Our new word crosses a chunk boundary, so create a new IndexedSpan
            line:appendSpan(IndexedSpan({ word }, chunkIndex))
        end

        return line
    end

    local nextWord
    local nextChunkIndex
    for index = 1, totalWordCount do
        nextWord = allWords[index]
        nextChunkIndex = getChunkIndex(index)

        local nextLine
        if accumulator == nil then
            nextLine = WrappedLine({ IndexedSpan({ nextWord }, 1) })
        else
            nextLine = addWord(nextWord, nextChunkIndex)
        end

        local fullLineText = nextLine:fullText()
        if font:getWidth(fullLineText) > wrapWidth then
            table.insert(finalWrappedLines, accumulator)
            accumulator = WrappedLine({ IndexedSpan({ nextWord }, nextChunkIndex) })
        else
            accumulator = nextLine
        end
    end

    if accumulator ~= nil then
        table.insert(finalWrappedLines, accumulator)
    end

    local concreteLines = std.iterate(finalWrappedLines)
        :map(ConcreteLine)
        :collect()

    return concreteLines
end

local function wrapTextToLines(text, font, wrapWidth)
    local words = lume.split(text)
    local lines = {}
    local currentLine
    while #words > 0 do
        local biggerLine
        if currentLine == nil then
            biggerLine = words[1]
        else
            biggerLine = currentLine.." "..words[1]
        end

        if font:getWidth(biggerLine) > wrapWidth then
            table.insert(lines, currentLine)
            currentLine = words[1]
        else
            currentLine = biggerLine
        end

        table.remove(words, 1)
    end
    if currentLine ~= "" then
        table.insert(lines, currentLine)
    end

    return lines
end

return {
    wrapTextToLines = wrapTextToLines,
    wrapAnnotatedTextToLines = wrapAnnotatedTextToLines,
}
