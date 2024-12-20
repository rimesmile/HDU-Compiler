package compiler_lexical_analysis
import std.collection.*
import std.console.*


main(): Int64 {

    // var input = "(a|b)*"
    // var input = "(aa)*"

    Console.stdOut.write("请输入正规式:")
    var input = Console.stdIn.readln().getOrThrow()

    // 数据预处理
    var (input_chs, lst) = preprocess(input)
    // 中缀 -> 后缀
    let postfix_str = infixToPostfix(lst)
    // 后缀 -> NFA
    let nfa = strToNFA(postfix_str)
    let nfa_accept_state = nfa.tail.index
    // 输出 NFA
    showNFA(nfa)

    NFATB_initial(nfa)

    // NFA -> DFA
    var (dfa_accept_state,dfa_sum) = NFAToDFA(nfa.head.index,input_chs,nfa_accept_state)
    
    // 输出 DFA
    showDFA(dfa_accept_state,dfa_sum)

    while (true) {
        Console.stdOut.write("请输入待检验的字符串:")
        var strToCheck = Console.stdIn.readln().getOrThrow()
        checkByNFA(strToCheck, nfa_accept_state)
        checkByDFA(strToCheck, dfa_accept_state, input_chs)
    }

    return 0
}