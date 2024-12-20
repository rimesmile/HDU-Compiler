package compiler_syntactic_analysis
import std.collection.*
import std.fs.*

class TrieNode{
    var childs = HashMap<Symbol, TrieNode>()
    var isEndOfWord = false

    func getFirstChild() {
    }

    public operator func ==(other: TrieNode):Bool {
        if (isEndOfWord != other.isEndOfWord) {
            return false
        }
        if (childs.size != other.childs.size) {
            return false
        }
        if (childs.keys().toArray() != other.childs.keys().toArray()) {
            return false
        }
        return true
    }

    public operator func !=(other: TrieNode): Bool {
        return !(this == other)
    }
}


class Trie {
    var root = TrieNode()
    
    Trie(rule: Rule) {
        // 生成 Trie 树
        for (right in rule.rights) {
            var node = root
            for (symbol in right) {
                if (!node.childs.contains(symbol)) {
                    node.childs[symbol] = TrieNode()
                }
                node = node.childs[symbol]
            }
            node.isEndOfWord = true
        }
    }

    func printTrie(output_arr:ArrayList<String>) {
        return _printTrie(root, "", output_arr)
    }

    private func _printTrie(
        node:TrieNode, 
        prefix:String,
        output_arr:ArrayList<String>,
        isLast!:Bool=true,
        symbol!:String=""
        ):Unit {
        
        if (node != this.root) {
            var connector = if (isLast) {"└──"} else {"├──"}
            output_arr.append("${prefix}${connector} ${symbol}")
        }

        var newPrefix = prefix + if (isLast){"    "} else {"│   "}
        var keys = node.childs.keys()
        var count = keys.size

        for ((index,symbol) in enumerate<Symbol>(keys)) {
            var isLastChild = index == count - 1
            _printTrie(
                node.childs[symbol], 
                newPrefix, 
                output_arr,
                isLast: isLastChild, 
                symbol: symbol)
        }
    }
    
}
