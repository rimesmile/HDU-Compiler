package compiler_syntactic_analysis
import std.collection.*
import std.fs.*
import std.console.*

// 消除左递归算法
func test1() {
        let g = Grammer()

        g.input("./src/input/1.txt")
        g.output('init')

        g.eliminateLeftRecursion()

        g.output('end')

        return 0
}

// 合并左公共因子
func test2() {
    let g = Grammer()

    g.input("./src/input/2.txt")
    g.output('init')

    println()
    
    g.extractLeftCommonFactors()

    g.output('after extractLeftCommonFactors')
    
    return 0
}

// FIRST FOLLOW
func test3() {
    let g = Grammer()

    g.input("./src/input/3.txt")
    g.output('init')

    g.getFirst(display: true)
    g.getFollow(display: true)
    
    return 0
}

// LL1 预测分析
func test4() {
    let g = Grammer()

    g.input("./src/input/4.txt")
    g.output('init')

    g.getFirst(display: true)
    g.getFollow(display: true)

    g.isLL1()

    g.initPT()

    g.printPT()

    while(true) {
        // var input_str ="aaaab"
        println()
        Console.stdOut.write("input:")
        var input_str = Console.stdIn.readln().getOrThrow()
        var input_arr = ArrayList<Symbol>()

        for (ch in input_str) {
            input_arr.append(String(Rune(ch)))
        }

        if (g.LL1_parser(input_arr)) {
            println('语法正确')
        }else {
            println("语法错误")
    }
    }

    return 0
}


main(): Int64 {
    test1()
    
    return 0
}