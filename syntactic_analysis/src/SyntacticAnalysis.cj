package compiler_syntactic_analysis
import std.collection.*
import std.fs.*

// 符号
type Symbol = String
type RightArray = ArrayList<ArrayList<String>>
type FSet = HashMap<Symbol, HashSet<Symbol>>

// 预测分析表
let PT = HashMap<Symbol, HashMap<Symbol, ArrayList<Symbol>>>()

// 规则
class Rule{

    var left: String
    var rights: RightArray
    
    init(left: String, rights: RightArray){
        this.left = left
        this.rights = rights
    }
    
    func clone() {
        return Rule(left.clone(), rights.clone())
    }
    
}

// 文法
class Grammer{
    var terminals = ArrayList<Symbol>()          // 终结符 
    var nonterminals =  ArrayList<Symbol>()      // 非终结符
    var rules = ArrayList<Rule>()                // 规则
    var start_symbol: String = ""
    var epsilon = 'ε'

    var first = FSet()
    var follow = FSet()

    // 输入文法规则
    func input(file_path:String) {
        let bytes = File.readFrom(file_path)
        var str = ""
        for (byte in bytes) {
            str += String(Rune(byte))
        }

        for (line in str.lines()) {
            var split_line = line.split('->')
            var left = split_line[0].trimEnd(' ')
            var rights = split_line[1].split('|')
            var format_rights = RightArray()
            
            for (right in rights) {
                var format_right = ArrayList<String>()
                var i = 0
                
                while (i < right.size) {
                    var ch = right[i]
                    if (ch == b' ') {
                        str = ""
                        i ++
                        continue
                    }
                    var str = String(Rune(ch))
                    // 找到一个起始字符为小写字母
                    if (ch.isAsciiLowerCase()) {
                        
                        while (i < right.size - 1 && right[i+1].isAsciiLowerCase()) {
                            i += 1
                            str += String(Rune(right[i]))
                        }
                        if (str == "ep") {
                            str = epsilon
                        }
                        format_right.append(str)
                        
                    }else {
                        format_right.append(str)
                    }
                    i += 1
                }
                format_rights.append(format_right)
            }
            this.insert(Rule(left, format_rights))
        }
        start_symbol = this.nonterminals[0]
    }

    // 插入规则
    func insert(rule:Rule) {

        for (it in this.rules) {
            // 如果规则左部存在
            if (it.left == rule.left) {
                for (right in rule.rights) {
                    if (!it.rights.contains(right)) {
                        it.rights.append(right)
                    }
                }
                return true
            }
        }
        // 规则不存在
        this.rules.append(rule)
        // 判断规则左部的非终结符号是否已存在
        if (!this.nonterminals.contains(rule.left)) {
            this.nonterminals.append(rule.left)
        }
        // 判断规则右部的符号是否已存在
        for (right in rule.rights) {
            for (symbol in right) {
                if (!this.nonterminals.contains(symbol) && !this.terminals.contains(symbol)) {
                    if (symbol[0] >= b'A' && symbol[0] <= b'Z') {
                        this.nonterminals.append(symbol)
                    }else {
                        this.terminals.append(symbol)
                    }
                }
            }
        }
        
        return true
    }

    // 拷贝
    func clone() {
        
        let new_g = Grammer()
        new_g.terminals = this.terminals.clone()
        new_g.nonterminals = this.nonterminals.clone()
        // new_g.rules = this.rules.clone()
        for (rule in this.rules) {
            new_g.rules.append(rule.clone())
        }

        return new_g
    }

    // 删除规则
    func remove(left: Symbol) {
        nonterminals.removeIf({i => i == left})
        rules.removeIf({i => i.left == left})
    }


    // 输出文法
    func output(desc:String) {
        println('--------${desc}---------')
        println('非终结符号:${nonterminals}')
        println('终结符号：${terminals}')
        println('规则：')
        for (rule in this.rules) {
            print('${rule.left} -> ')

            for (r in 0..rule.rights.size) {
                for (symbol in rule.rights[r]) {
                    print(symbol)
                }
                if (r != rule.rights.size - 1) {
                    print(' | ')
                }
            }
            
            println()
        }
    }

    public operator func [](index: String) {
        if (nonterminals.contains(index)) {
            for (rule in rules) {
                if (rule.left == index) {
                    return rule.rights
                }
            }
        }
        return RightArray()
    }

    // 消除直接左递归
    func eliminateDirectLeftRecursion() {
        let pre = this.rules.clone()
        this.rules.clear()

        for (r in pre) {
            if (!hasLeftRecursion(r)) {
                this.rules.append(r)
                continue
            }

            let A = r.left
            var alpha = RightArray()  // alpha是所有以A开头的产生式
            var beta = RightArray()   // beta是所有不以A开头的产生式

            for (right in r.rights) {
                if (right[0] == A) {
                    alpha.append(right.slice(1..right.size))
                }else {
                    beta.append(right)
                }
            }

            var A1 = A + "'"
            while (this.nonterminals.contains(A1)) {
                A1 += "'"
            }
            this.nonterminals.append(A1)

            // 添加规则1: A->beta A'
            var new_rule_1 = Rule(A, RightArray())
            for (right in beta) {
                if (right[0] != "ε") {
                    var new_right = right.clone()
                    new_right.append(A1)
                    new_rule_1.rights.append(new_right)
                }else {
                    new_rule_1.rights.append(ArrayList<Symbol>([A1]))
                }
            }
            this.rules.append(new_rule_1)

            // 添加规则2: A'-> alpha A'
            var new_rule_2 = Rule(A1, RightArray())
            for (right in alpha) {
                var new_right = right.clone()
                new_right.append(A1)
                new_rule_2.rights.append(new_right)
            }
            new_rule_2.rights.append(ArrayList<Symbol>(["ε"]))
            this.rules.append(new_rule_2)
        }
        pre.clear()
    }


    // 消除包含间接在内的所有左递归
    func eliminateLeftRecursion() {
        // 遍历非终结符号
        for (i in 0..nonterminals.size) {
            var A_i = nonterminals[i]
            
            for (j in 0..i) {
                var A_j = nonterminals[j]
                
                for (k in 0..this[A_i].size) {
                    let right_i = this[A_i][k]
                    // 将每个 A_i -> A_j gamma 替换为 A_i -> right_j gamma
                    if (right_i[0] == A_j) {
                        
                        var gamma = right_i.slice(1..right_i.size)
                        var new_rule = Rule(A_i, RightArray())

                        for (right_j in this[A_j]) {
                            var new_right = right_j.clone()
                            new_right.appendAll(gamma)
                            new_rule.rights.append(new_right)
                        }

                        this[A_i].removeIf({i => i == right_i})
                        this.insert(new_rule)
                    }
                    
                }
            }
            // 消除产生式的直接左递归
            this.eliminateDirectLeftRecursion()
        }
        
        output('before simplify')
        
        // 文法化简
        let stack = LinkedList<Symbol>()
        let processed_nonterminals = ArrayList<Symbol>()
        // 加入文法的开始符号
        stack.append(nonterminals[0])
        while (!stack.isEmpty()) {
            var left = stack.popFirst().getOrThrow()
            var rights = this[left]

            processed_nonterminals.append(left)
            // 查看是否需要加入其他的非终结符号
            for (right in rights) {
                for (symbol in right) {
                    
                    if (symbol[0] >= b'A' && symbol[0] <= b'Z' && !processed_nonterminals.contains(symbol)) {
                        stack.append(symbol)
                    }
                }
            }
        }

        for (nt in nonterminals) {
            if (processed_nonterminals.contains(nt)) {
                continue
            }
            println('删除非终结符号 ${nt} 所含有的规则')
            this.remove(nt)
        }
    }

    // 遍历字典树重构规则 递归
    func traverseTrie(raw_root:TrieNode, left: Symbol, raw_right: ArrayList<Symbol>): Unit {
        var root = raw_root
        var right = raw_right
        // 压缩路径:若当前节点只有一个子节点，则继续遍历树
        while (root.childs.size == 1) {
            
            if (root.isEndOfWord) {
                insert(Rule(left, RightArray(right.clone())))
            }
            for ((key,node) in root.childs) {
                right.append(key)
                root = node
            }
            
        }

        // 处理叶子节点
        if (root.childs.size == 0 && root.isEndOfWord) {
            insert(Rule(left, RightArray(right.clone())))
        }else {
            // 处理分叉节点
            var new_left = left
            while (nonterminals.contains(new_left)) {
                new_left += "'"
            }
            this.nonterminals.append(new_left)
            
            // 将非终结符号加入当前规则的右部
            var new_right = right
            new_right.append(new_left)
            
            // 添加规则  S -> applS'
            insert(Rule(left, RightArray(new_right.clone())))

            new_right.clear()
            // 遍历子节点 S' -> a | b
            for ((key,node) in root.childs) {
                new_right.append(key)
                traverseTrie(node, new_left, new_right.clone())
                new_right.clear()
            }

        }
    }
    
    
    // 提取左公因式并修改文法
    func extractLeftCommonFactors() {
        var pre_rules = rules.clone()
        var output_str = ""
        rules.clear()
        for (rule in pre_rules) {
            var trie = Trie(rule)
            var root = trie.root
            var left = rule.left
            var right = ArrayList<Symbol>()

            for ((key,node) in root.childs) {
                right.append(key)
                traverseTrie(node, left, right)
                right.clear()
            }
            output_str += "    ${left}\n"
            var output_arr = ArrayList<String>()
            // 前缀树
            trie.printTrie(output_arr)

            for (line in output_arr) {
                output_str += (line + '\n')
            }

        }

        // 前缀树写入文件
        let file = File("./src/output/trie.txt", OpenOption.Truncate(true))
        file.write(output_str.toArray())
    }

    

    // 计算 FIRST 集合
    private func computeFirst(symbol:Symbol,visited:HashSet<Symbol>): Unit{
        if (visited.contains(symbol)) {
            return
        }
        visited.put(symbol)

        var first_set = HashSet<Symbol>()
        for (right in this[symbol]) {
            
            for (r in right) {
                if (terminals.contains(r)) {
                    first[symbol].put(r)
                    break
                }else {
                    computeFirst(r, visited)
                    var hasEpsilon = false
                    for (f in first[r]) {
                        if (f == epsilon) {
                            hasEpsilon  = true
                        }else {
                            first[symbol].put(f)
                        }
                    }
                    if (!hasEpsilon) {
                        break
                    }
                }
            }
        }
        visited.remove(symbol)
    }
    

    // 获取 FIRST 集合
    func getFirst(display!:Bool = false) {
        if (!first.isEmpty()) {
            if (display) {
                println('FIRST:${first}')
            }
            return first
        }

        // 初始化
        for (nt in nonterminals) {
            first[nt] = HashSet<Symbol>()
        }
        var visited = HashSet<Symbol>()
        for (nt in nonterminals) {
            computeFirst(nt, visited)
        }
        if (display) {
            println('FIRST:${first}')
        }
        return first
    }


    // 计算 Follow 集合
    private func computeFollow(symbol:Symbol, visited: HashSet<Symbol>): Unit{
        if (visited.contains(symbol)) {
            return
        }
        // visited 待处理字符列表
        visited.put(symbol)

        for (rule in rules) {
            for (right in rule.rights) {
                for (i in 0..right.size) {
                    if (right[i] == symbol) {
                        if (i < right.size - 1) {
                            var next_symbol = right[i+1]
                            // 如果下一符号是终结符，加入FOLLOW
                            if (terminals.contains(next_symbol)) {
                                follow[symbol].put(next_symbol)
                            }else {
                                // [A -> alpha B beta] 
                                // => FIRST(beta) -> Follow(B)
                                for (f in first[next_symbol]) {
                                    if (f != epsilon) {
                                        follow[symbol].put(f)
                                    }
                                }
                                // [A -> alpha B beta] + beta -> epsilon
                                // => FOLLOW(A)-> Follow(B)
                                if (first[next_symbol].contains(epsilon)) {
                                    computeFollow(rule.left, visited)
                                    for (f in follow[rule.left]) {
                                        follow[symbol].put(f)
                                    }
                                }
                            }
                        }else {
                            computeFollow(rule.left, visited)
                            for (f in follow[rule.left]) {
                                follow[symbol].put(f)
                            }
                        }
                    
                    }
                }
                
            }
        }
        visited.remove(symbol)
    }


    // 获取 FOLLOW 集合
    func getFollow(display!:Bool = false) {
        if (!follow.isEmpty()) {
            if (display) {
                println('FOLLOW:${follow}')
            }
            return follow
        }

        // 初始化
        for (nt in nonterminals) {
            follow[nt] = HashSet<Symbol>()
        }
        // 
        follow[start_symbol].put("$")

        var visited = HashSet<Symbol>()
        for (nt in nonterminals) {
            computeFollow(nt, visited)
        }
        if (display) {
            println('FOLLOW:${follow}')
        }
        return follow
    }

    // 计算产生式的Select集合
    func computeSelect(left:Symbol, right: ArrayList<Symbol>) {
        getFirst()
        getFollow()
        var first_set = HashSet<Symbol>()

        for (r in right) {
            if (terminals.contains(r)) {
                first_set.put(r)
                break
            }else {
                
                for (f in first[r]) {
                    if (f != epsilon) {
                        first_set.put(f)
                    }
                }
                
                if (!first[r].contains(epsilon)) {
                    break
                }else {
                    if (r == right[right.size-1]) {
                        first_set.putAll(follow[left])
                    }
                }
                
            }
        }
        return first_set
    }
    
    // 判断是否是LL1文法
    func isLL1() {
        getFirst()
        getFollow()

        for (rule in rules) {
            var convergance = HashSet<Symbol>()
            for (right in rule.rights) {
                var rule_first_set = computeSelect(rule.left, right)
                for (rfs in rule_first_set) {
                    if (convergance.contains(rfs)) {
                        return false
                    }
                }
                convergance.putAll(rule_first_set)
            }
        }
        return true
    }

    func initPT() {
       if (!isLL1()) {
            println('不是 LL(1) 文法')
        }
        if (!PT.isEmpty()) {
            return true
        }
        // PT 初始化
        for (nt in nonterminals) {
            var tmp = HashMap<Symbol, ArrayList<Symbol>>()
            for (t in terminals) {
                if (t == epsilon) {
                    continue
                }
                tmp.put(t, ArrayList<Symbol>())
            }
            tmp.put("$", ArrayList<Symbol>())
            PT.put(nt, tmp)
        }

        for (rule in rules) {
            var left = rule.left
            for (right in rule.rights) {
                var first_set = computeSelect(rule.left, right)
                for (t in first_set) {
                    if (t != epsilon) {
                        PT[left][t] = right
                    }
                }
                if (first_set.contains(epsilon)) {
                    for (next_t in follow[left]) {
                        PT[left][next_t] =  right
                    }
                }
            }
        }
        return true
    }


    func printPT() {
        if (PT.isEmpty()) {
            return false
        }
        println('------ PT ------')
        print('\t')
        var new_terminals = ArrayList<Symbol>()
        for (t in terminals) {
            if (t != epsilon) {
                new_terminals.append(t)
            }
        }
        new_terminals.append("$")

        for (t in new_terminals) {
            print('${t}\t')
        }
        print('\n')
        for (nt in nonterminals) {
            print('${nt}\t')
            for (t in new_terminals) {
                if (PT[nt][t].isEmpty()) {
                    print('\t')
                    continue
                }
                var str = ""
                for (r in PT[nt][t]) {
                    str += r
                }
                print('${nt}->${str}\t')
            }
            print('\n')
        }
        println('------    ------')
        return true
    }

    func LL1_parser(input: ArrayList<Symbol>) {
        // 生成预测分析表
        if (!initPT()) {
            println('生成预测分析表失败')
            return false
        }

        var stack = LinkedList<Symbol>()
        stack.append(start_symbol)

        var input_buff = input.clone()
        input_buff.append("$")

        while (!stack.isEmpty()) {
            var top = stack.popLast().getOrThrow()
            var current_symbol = input_buff[0]

            if (terminals.contains(top)) {
                if (top == current_symbol) {
                    input_buff = input_buff.slice(1..input_buff.size)
                }else {
                    return false
                }
            }else {
                var right = PT[top][current_symbol]
                if (!right.isEmpty()) {
                    var reverse_right = right.clone()
                    reverse_right.reverse()
                    for (r in reverse_right) {
                        if (r != epsilon) {
                            stack.append(r)
                        }
                    }
                }else {
                    return false
                }
            }
            
        }
        if (input_buff[0] == "$") {
                return true
            }
        return false
    }
}

// 判断文法是否有直接左递归
func hasLeftRecursion(rule: Rule) {
    let A = rule.left
    for (right in rule.rights) {
        if (right[0] == A) {
            return true
        }
    }
    return false
}

