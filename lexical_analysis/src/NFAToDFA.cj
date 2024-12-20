package compiler_lexical_analysis
import std.collection.*

class DFAState{
    var index: Int64
    var input = ArrayList<Rune>()
    var chTrans = ArrayList<Int64>()
    init(index: Int64){
        this.index = index
    }
}

let DFAStates = Array<DFAState>(MAXSIZE){i => DFAState(i)}

var states_closure = HashMap<Int64, HashSet<Int64>>()

func ep_closure(state:Int64,closure_cache:HashMap<Int64, HashSet<Int64>>) {

    // 检查这个状态的闭包是否已经被计算过
    if(closure_cache.contains(state)){
        return closure_cache[state]
    }
    
    var closure = HashSet<Int64>([state])

    var stack = LinkedList<Int64>([state])

    while (!stack.isEmpty()) {
        var current_state = stack.popLast().getOrThrow()
        if (NFA_TB.contains(current_state)) {
            if (NFA_TB[current_state].contains(r'#')) {
                for (next_state in NFA_TB[current_state][r'#']){
                    if (!closure.contains(next_state)){
                        closure.put(next_state)
                        stack.append(next_state)
                    }
                }
                
            }
        }
    }

    closure_cache[state] = closure

    return closure
}

func DFA_edge(dfa_state:HashSet<Int64>,input:Rune){
    // 初始化下一个状态的集合
    var next_dfa_state = HashSet<Int64>()
    // 对于当前DFA状态中的每个NFA状态
    for (nfa_state in dfa_state){
        // 如果这个NFA状态在NFA转换表中有对应输入符号的转换
        if (NFA_TB.contains(nfa_state) && NFA_TB[nfa_state].contains(input)) {
            for (next_nfa_state in NFA_TB[nfa_state][input]) {
                next_dfa_state.putAll(ep_closure(next_nfa_state, states_closure))
            }
        }
    }
    // 返回下一个DFA状态（即所有可能NFA状态的epsilon闭包的并集）
    return next_dfa_state
}



func getIndex(data:ArrayList<HashSet<Int64>>, item:HashSet<Int64>){
    var i = 0;
    while (i < data.size) {
        if (data[i] == item) {
            return i
        }
        i++
    }
    return -1
}



func NFAToDFA(initial_state:Int64, input_chs:ArrayList<Rune>,nfa_accept_state:Int64) {
    let Dstates = ArrayList<HashSet<Int64>>()

    Dstates.append(ep_closure(initial_state, states_closure))

    var p = 0
    var j = 0
    var accept_state = HashSet<Int64>()

    while (j <= p) {
        for (ch in input_chs) {
            
            var e = DFA_edge(Dstates[j], ch)

            if (e.isEmpty()) {
                DFAStates[j].input.append(ch)
                DFAStates[j].chTrans.append(-1)
                continue
            }

            var i = getIndex(Dstates, e)

            // 判断是否已有子集状态，若有
            if (i != -1) {
                DFAStates[j].input.append(ch)
                DFAStates[j].chTrans.append(i)
            }else {
                p++
                Dstates.append(e)
                DFAStates[j].input.append(ch)
                DFAStates[j].chTrans.append(p)
            }
            if (e.contains(nfa_accept_state)) {
                    accept_state.put(j+1)
            }
            
        }
        j++
    }

    return (accept_state, p+1)

}




func showDFA(dfa_accept_state:HashSet<Int64>,dfa_sum:Int64) {
    println("-------------- DFA --------------")
    println("状态总数:${dfa_sum}")
    println("初始状态:${0}, 接受状态:${dfa_accept_state}")
    println("状态转化集合:")

    for (state in DFAStates){
        if (state.input.isEmpty()) {
            break
        }

        for (i in 0..state.input.size) {
            if (state.chTrans[i] == -1) {
                continue
            }
            print("${state.index} --> ${state.input[i]} --> ${state.chTrans[i]} \t")
        }

        print('\n')
    }
    println("-------------------------------")
}

func checkByDFA(str:String,accept_state:HashSet<Int64>,input_chs:ArrayList<Rune>){
    var state = 0
    var strToCheck = str + '$'
    var i = 0
    var ch = Rune(strToCheck[i])
    while(ch != r'$'){
        if (!(input_chs.contains(ch))) {
            println('DFA 结果：不接受')
            return false
        }
        for (j in 0..DFAStates[state].input.size) {
            if (ch == DFAStates[state].input[j]) {
                state = DFAStates[state].chTrans[j]
                i++
                ch = Rune(strToCheck[i])
                break
            }
        }
        if (state == -1) {
            println('DFA 结果：不接受')
            return false
        }
    }
    if (accept_state.contains(state)) {
        println('DFA 结果：接受')
        return true
    }else {
        println('DFA 结果：不接受')
        return false
    }
    
}