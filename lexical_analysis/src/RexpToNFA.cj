package compiler_lexical_analysis
import std.collection.*
import std.console.*

const MAXSIZE = 128 // 128


class NFAState{
    static var count = 0
    var index: Int64
    var input: Option<Rune> =  None
    var chTrans: Option<Int64> = None
    var epTrans: HashSet<Int64> = HashSet<Int64>(MAXSIZE)
    init(index: Int64){
        this.index = index
    }
    
}

let NFAStates = Array<NFAState>(MAXSIZE){i => NFAState(i)}

class NFA{
    var head: NFAState
    var tail: NFAState

    init(){
        this.head = NFAStates[NFAState.count] 
        this.tail = NFAStates[NFAState.count + 1]
    }

    static public func add(n1: NFAState, n2: NFAState, ch:Rune){
        n1.input = ch
        n1.chTrans = n2.index
    }

    static public func add(n1: NFAState, n2: NFAState){
        n1.epTrans.put(n2.index)
    }
}

// 字符串预处理
// 在第一位是操作数、'*'或')'且第二位是操作数或'('之间加入连接符'&'
func preprocess(str:String){
    var i = 0
    var length = str.size
    var lst = ArrayList(str.toArray())
    var input_chs = ArrayList<Rune>()
    
	while (i < length - 1)
	{
		if ((lst[i] >= b'a' && lst[i] <= b'z') || (lst[i] == b'*') || (lst[i] == b')'))
		{
			if ((lst[i + 1] >= b'a' && lst[i + 1] <= b'z') || lst[i + 1] == b'(')
			{
                lst.insert(i + 1, b'&')
				length++
			}
		}
		i++;
	}

    for (s in str) {
        if (s >= b'a' && s <= b'z' && (!input_chs.contains(Rune(s)))) {
            input_chs.append(Rune(s))
        }
    }
    

    // 将 lst 转换为字符串
    var result = ""
    for (ascii_val in lst){
        result += String(Rune(ascii_val))
    }

    println("字符串预处理:${result}")

    return (input_chs, lst)
}

// 中缀转后缀时用到的优先级比较
// 为每个操作符赋一个权重，通过权重大小比较优先级
func priority(ch:UInt8){
	return match (ch) {
        case b'*' => 3
        case b'&' => 2
        case b'|' => 1
        case b'(' => 0
        case _ => -1
    }
}

// 中缀转后缀表达式
func infixToPostfix(lst:ArrayList<UInt8>) {
    
    let op_stack = LinkedList<UInt8>()
    var postfix_lst = ArrayList<UInt8>()
    

    for (i in lst) {
        if (i >= b'a' && i <= b'z') {
            postfix_lst.append(i)
        }else {
            if (i == b'(') {
                op_stack.append(i)
            }else if(i == b')'){

                while (true) {
                    var top = op_stack.popLast().getOrThrow()
                    
                    if (top == b'(') {
                        break
                    }
                    postfix_lst.append(top)
                }

            }else {
                if (!op_stack.isEmpty()) {
                    var top = op_stack.lastNode().getOrThrow().value
                    while (priority(top) >= priority(i)) {

                        postfix_lst.append(top)
                        op_stack.popLast().getOrThrow()

                        if (op_stack.isEmpty()) {
                            break
                        }else {
                            top = op_stack.lastNode().getOrThrow().value
                        }
                    }
                    op_stack.append(i)
                    }else {
                        op_stack.append(i)
                    }
                    
                }
            }
        }

        while (!op_stack.isEmpty()) {
            var top = op_stack.popLast().getOrThrow()

            postfix_lst.append(top)
        }

        var postfix_str = ""
        for (i in postfix_lst) {
            postfix_str += String(Rune(i))
        }
        println("后缀表达式:${postfix_str}")
        return postfix_str
    }





// 后缀表达式转 NFA
func strToNFA(str:String) {
    let NFAStack = LinkedList<NFA>()
    for (ch in str){
        if (ch >= b'a' && ch <= b'z'){
            let nfa = NFA()
            NFAState.count += 2

            NFA.add(nfa.head, nfa.tail, Rune(ch))

            NFAStack.append(nfa)
        }else if (ch == b'*'){
            let n2 = NFA()
            NFAState.count += 2
            let n1 = NFAStack.popLast().getOrThrow()
            
            NFA.add(n1.tail, n2.head)
            NFA.add(n1.tail, n2.tail)
            NFA.add(n2.head, n1.head)
            NFA.add(n2.head, n2.tail)

            NFAStack.append(n2)
        }else if(ch == b'|'){
            let n2 = NFAStack.popLast().getOrThrow()
            let n1 = NFAStack.popLast().getOrThrow()
            let n3 = NFA()
            NFAState.count += 2
            
            NFA.add(n3.head, n1.head)
            NFA.add(n3.head, n2.head)
            NFA.add(n1.tail, n3.tail)
            NFA.add(n2.tail, n3.tail)

            NFAStack.append(n3)
        }else if(ch == b'&'){
            let n2 = NFAStack.popLast().getOrThrow()
            let n1 = NFAStack.popLast().getOrThrow()
            let n3 = NFA()

            NFA.add(n1.tail, n2.head)

            n3.head = n1.head
            n3.tail = n2.tail

            NFAStack.append(n3)
        }
    }
    return NFAStack.popLast().getOrThrow()
}

let NFA_TB = HashMap<Int64, HashMap<Rune, HashSet<Int64>>>()

func NFATB_initial(last_nfa:NFA) {
    
    for (i in 0..last_nfa.tail.index){

        if(!NFAStates[i].chTrans.isNone()){
            NFA_TB.put(i, 
            HashMap<Rune, HashSet<Int64>>([(NFAStates[i].input.getOrThrow(),
            HashSet<Int64>([NFAStates[i].chTrans.getOrThrow()]))]))
        }

        if (!NFAStates[i].epTrans.isEmpty()) {
            NFA_TB.put(i, HashMap<Rune, HashSet<Int64>>([(r'#',NFAStates[i].epTrans)]))

        }
    }

    return NFA_TB
}

// 展示 NFA 函数
func showNFA(nfa:NFA){
    println("-------------- NFA --------------")
    println("状态总数:${nfa.tail.index}")
    println("初始状态:${nfa.head.index}, 接受状态:${nfa.tail.index}")
    println("状态转化集合:")

    for (state in NFAStates){
        if (state.index == nfa.tail.index) {
            break
        }
        if (state.input != None){
            print("${state.index} --> ${state.input.getOrThrow()} --> ${state.chTrans.getOrThrow()} \t")
        }

        for (it in state.epTrans){
            print("${state.index} --> ε --> ${it} \t")
        }
        print('\n')
    }
    println("-------------------------------")

}

func checkByNFA(str:String,accept_state:Int64) {
    var state = 0
    var strToCheck = str + '$'
    var i = 0
    var ch = Rune(strToCheck[i])
    var closure = ep_closure(state, states_closure)
    while(ch != r'$'){
        closure = DFA_edge(closure, ch)
        if (closure.isEmpty()) {
            println('NFA 结果：不接受')
            return false
        }
        i ++
        ch = Rune(strToCheck[i])
    }
    
    if (closure.contains(accept_state)) {
        println('NFA 结果：接受')
    }else {
        println('NFA 结果：不接受')
    }
    return true

}

