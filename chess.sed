#n
1s/.*/\
    @\
    figures()\
    label(loop)\
        board()\
        input()\
        move()\
        select-figures(n)\
        label(knight)\
            iter-knight()\
            break-if-end(knight)\
            set-array()\
            estimate-black-pieces()\
            estimate-black-knight()\
            sum-array()\
            delete-last-board()\
            store-iter()\
        back(knight)\
        find-best-move()\
        log()\
    back(loop)\
/


# estimate-black-pieces()\
# estimate-black-queen()\
# estimate-black-knight()\
# estimate-black-pawn()\
# estimate-black-king()\
# estimate-black-bishop()\
# estimate-black-queen()\


# оценки запрограммированы по матрицам из книги
# «Программирование шахмат и других логических игр» Корнилова Евгения Николаевича

# переформатирование команд
1s/ *//g; 1s/\n/ /g; 1s/^ //

# обработка поступающей команды
1!{
    /^[a-h][1-8] *[a-h][1-8]$/ {
        # добавляем полученные значения впереди стека исполнения
        G; s/\n/ /
        # переходим на исполнение команд
        b @
    }

    # игрок хочет выйти
    /^q/ q

    # введена какая-то ерунда, стираем и возвращаем стек команд
    i\
    [12H[J[1A
    s/.*//

    g
    b
}

:@
s/@\([^ ]* \)/\1@/

# начать массив
/@set-array()/ {
    s/^/ARRAY /
    b @
}

# метка
/@label(/ {
    b @
}

# переход к метке
/@back(/ {
    s/label(\([^)]*\))\(.*\)@back(\1)/@label(\1)\2back(\1)/
    b @
}

# выход из цикла, если на вершине END
/@break-if-end(/ {
    /^END */{
        s///
        s/@break-if-end(\([^)]*\))\(.*\)back(\1)/break-if-end(\1)\2@back(\1)/
    }
    b @
}

# ввод данных
/@input()/ {
    h; b
}

# удаление последней доски
/@delete-last-board()/ {
    s/\(.*\)Board:[^ ]* */\1/
    b @
}

# дублирование доски
/@copy-board()/ {
    s/\(Board:[^ ]*\)/\1 \1/
    b @
}

# генерация начального состояния доски
/@figures()/ {
    # формат: XYFig
    # координаты белых тут и дальше должны идти НИЖЕ чёрных
    # БОЛЬШИЕ — чёрные, маленькие — белые
    s/^/Board:\
a8Rb8Nc8Id8Qe8Kf8Ig8Nh8R\
a7Pb7Pc7Pd7Pe7Pf7Pg7Ph7P\
a6 b6 c6 d6 e6 f6 g6 h6 \
a5 b5 c5 d5 e5 f5 g5 h5 \
a4 b4 c4 d4 e4 f4 g4 h4 \
a3 b3 c3 d3 e3 f3 g3 h3 \
a2pb2pc2pd2pe2pf2pg2ph2p\
a1rb1nc1id1qe1kf1ig1nh1r /
# пробел в конце нужен!

    s/\n//g

    b @
}

# вывод доски
/@board()/ {
    # сохраняем стек команд
    h
    # убираем всё, кроме доски (берём всегда последнюю доску)
    s/.*Board://
    s/ .*$//
    # расшифровываем доску
    # Pawn, Queen, King, bIshop, kNight, Rook
    y/pqkinrPQKINR12345678abcd/♟♛♚♝♞♜♙♕♔♗♘♖987654323579/
    s/\([1-9e-h]\)\([1-9]\)\(.\)/[\2;\1H\3 /g

    # расцвечиваем
    s/[8642];[37eg]H/&[48;5;209;37;1m/g
    s/[9753];[37eg]H/&[48;5;94;37;1m/g
    s/[8642];[59fh]H/&[48;5;94;37;1m/g
    s/[9753];[59fh]H/&[48;5;209;37;1m/g

    # двузначные числа
    s/e/11/g;s/f/13/g;s/g/15/g;s/h/17/g

    s/$/[0m[11H/
    # выводим доску и возвращаем всё как было
    i\
[2J[1;3Ha b c d e f g h\
8\
7\
6\
5\
4\
3\
2\
1\
\
Enter command:
    p
    g

    b @
}

# делаем ход по введённым пользователем данным
/@move()/ {
    # гарды основных регулярок (их нужно тщательно защищать от несрабатываний,
    # иначе sed выдаст ошибку и остановится)
    # вычищаем всё, кроме доски и первых двух значений
    h; s/\([^ ]*\) \([^ ]*\).*Board:\([^ ]*\).*/\1 \2 \3/
    
    # выделяем указанные клетки
    s/\([^ ]*\) [^ ]* .*\(\1.\)/&(1:\2)/
    s/[^ ]* \([^ ]*\) .*\(\1.\)/&(2:\2)/
    # теперь они имеют формат:
    # номер_по_порядку_ввода:XYФигура
    s/.*(\(.....\)).*(\(.....\)).*/\1 \2/

    # теперь надо проверить:
    # 1. что берём не чужую и не пустую фигуру
    /1:..[PQKINR ]/ {
        g; s/[^ ]* [^ ]* *//; b @
    }

    # 2. не кладём на место своей фигуры
    /2:..[pqkbnr]/ {
        g; s/[^ ]* [^ ]* *//; b @
    }

    # порядок такой:
    # указанные координаты у найденных фигур меняем между собой

    # если ход будет вперёд…
    /2:.*1:/ {
        g
        #    1        2                3          4       5           6
        /\([^ ]*\) \([^ ]*\) \(.*Board:[^ ]*\)\2\(.\)\([^ ]*\)\1\([pqkbnr]\)/ {
            s//\3\1\4\5\2\6/
            b @
        }
    }

    # ход назад
    g
    #     1         2            3                4          5        6
    s/\([^ ]*\) \([^ ]*\) \(.*Board:[^ ]*\)\1\([pqkbnr]\)\([^ ]*\)\2\(.\)/\3\2\4\5\1\6/
    b @
}

# количество оставшихся фигур
/@count-pieces()/ {
    h
    # убираем всё, кроме доски
    s/.*Board://
    s/ .*$//
    # убираем всё, кроме белых фигур
    s/[^pqkbnrPQKINR]//g
    # считаем
    s/./1/g
    # возвращаем стек команд
    G
    # после G появился перевод строки, убираем его
    s/\n/ /

    b @
}

#оценочная функция имеющихся чёрных фигур
/@estimate-black-pieces()/ {
    # пешка — 100, слон и конь — 300, ладья — 500, ферзь — 900

    # очистка всего лишнего
    h; s/.*Board://; s/ .*$//
    # убираем всё, кроме подсчитываемых фигур
    s/[^PINRQ]//g
    # считаем количество * коэффициент фигуры (ферзь Q — единственный)
    s/P/1/g; s/[IN]/111/g; s/R/11111/g; s/Q/111111111/

    # группируем сотни и тысячи
    s/1111111111/H/g; s/HHHHHHHHHHH/T/g; s/\(.\)\1*/&:/g; s/[ :]*$/::/; y/HT/11/

    # добавляем к сохранённому стеку
    G; s/\n/B /

    b @
}

#для отладки: вывод текущего стека
/@log()/ {
    l
    q
}

#оценочная функция для позиции чёрных пешек
/@estimate-black-pawn()/ {
    # очистка всего лишнего
    h; s/.*Board://; s/ .*$//
    # оставляем только чёрные и белые пешки, перекодируем их в понятные координаты
    # теперь пешки записаны вот так: XЦвет (где Цвет — Black или White), разделены пробелом
    s/[a-h][1-8][^Pp]//g; y/Ppabcdefgh/WB12345678/; s/\([1-8]\)[1-8]/ \1/g

    # → Этап 1
    # ищем чёрные пешки, на вертикали у которых стоят белые, координаты белых идут
    # всегда ПЕРЕД координатами чёрных
    :estimate-black-pawn::black
    /\([1-8]\)W\(.*\1\)B/ {
        s//\1W\2b/
        b estimate-black-pawn::black
    }

    # → Этап 2.1
    # переводим координаты в последовательности длины X
    :estimate-black-pawn::x
    /[2-8]/ {
        s/[2-8]/1&/g
        y/2345678/1234567/

        b estimate-black-pawn::x
    }

    # → Этап 2.2
    # ищем пешки, не отсеянные на этапе 1, у которых на соседней линии слева стоят белые
    :estimate-black-pawn::left
    /\( 1*\)W\(.*\11\)B/ {
        s//\1W\2b/
        b estimate-black-pawn::left
    }

    # → Этап 2.3
    # ищем пешки, не отсеянные на этапе 2, у которых на соседней линии справа стоят белые
    :estimate-black-pawn::right
    / 1\(1*\)W\(.* \1\)B/ {
        s// 1\1W\2b/
        b estimate-black-pawn::right
    }

    # В итоге, W — белые пешки, b — чёрные, B — чёрные свободные пешки
    # избавляемся от несвободных и белых пешек
    s/ [^ ]*[Wb]//g

    # → Этап 3
    # считаем стоимости чёрных свободных пешек
    s/ 1B//; s/ 11B/ ::11111B/; s/ 111B/ :1:B/; s/ 1111B/ :1:11111B/; s/ 11111B/ :11:B/
    s/ 111111B/ :111:B/; s/ 1111111B/ 1:1111:B/; s/ 11111111B//

    # → Этап 4
    # сохраняем полученное, грузим стек обратно, вырезаем доску и оставляем чёрные пешки с координатами
    G; h; s/.*Board://; s/ .*$//; s/[a-h][1-8][^p]//g

    # оцениваем позиции всех пешек
    s/.[81]p/::B/g

    s/[abcfgh]7p/::1111B/g; s/[de]7p/::B/g

    s/[ah][65]p/::111111B/g; s/[bg][65]p/::11111111B/g; s/[cf]6p/::11B/g; s/[de]6p/:1:B/g

    s/[bg]5p/:1:11B/g; s/[cf]5p/:1:111111B/g; s/[de]5p/:11:1111B/g

    s/[ah]4p/::11111111B/g; s/[bg]4p/:1:11B/g; s/[cf]4p/:1:111111B/g; s/[de]4p/:11:1111B/g

    s/[ah][32]p/:1:11B/g; s/[bg][32]p/:1:111111B/g; s/[cf][32]p/:11:1111B/g; s/[de][32]p/:111:11B/g

    # вставляем пробелы между оценками
    s/B/& /g; s/^/ /

    # → Этап 5
    # возвращаем сохранённые оценки, убираем остатки стека
    G; s/\n\(.*\)\n.*/ \1/

    # добавляем к сохранённому стеку, вычищаем наш мусор, который мы складывали выше —
    # там второй строкой лежат оценки
    G; s/\n.*\n/ /

    b @
}

#оценочная функция для позиции чёрного короля
/@estimate-black-king()/ {
    h; s/.*Board://; s/ .*$//

    # выделяем короля
    s/[a-h][1-8][^k]//g

    # считаем его вес (матрица конца игры)
    s/[ah][18]./::/
    
    s/[de][54]./:111:111111/
    
    s/[cf][54]./:111:/; s/[de][63]./:111:/

    s/[bg][54]./:11:1111/; s/[de][72]./:11:1111/; s/[cf][63]./:11:1111/

    s/[de][18]./:1:11111111/; s/[ah][54]./:1:11111111/; s/[cf][72]./:1:11111111/; s/[bg][63]./:1:11111111/

    s/[bg][72]./:1:11/; s/[ah][63]./:1:11/; s/[cf][81]./:1:11/

    s/[a-h][1-9]./::111111/

    G; s/\n/B /

    b @
}

#оценочная функция для позиции чёрного коня
/@estimate-black-knight()/ {
    h; s/.*Board://; s/ .*$//

    # выделяем коней
    s/[a-h][1-8][^n]//g

    # считаем их вес
    s/[ah][18]./::B/g
    
    s/[de][54]./:111:11B/g
    
    s/[cf][54]./:11:11111111B/g; s/[de][63]./:11:11111111B/g

    s/[cf][36]./:11:1111B/g

    s/[bg][54]./:11:B/g; s/[de][72]./:11:B/g; s/[cf][63]./:11:B/g

    s/[de][18]./:1:B/g; s/[ah][54]./:1:B/g; s/[cf][72]./:1:B/g; s/[bg][63]./:1:B/g

    s/[bg][72]./::11111111B/g; s/[ah][63]./::11111111B/g; s/[cf][81]./::11111111B/g

    s/[a-h][1-9]./::1111B/g

    G; s/\n/ /

    b @
}

#оценочная функция для позиции чёрного слона
/@estimate-black-bishop()/ {
    h; s/.*Board://; s/ .*$//

    # выделяем слонов
    s/[a-h][1-8][^i]//g

    # считаем их вес
    s/[a-h][81]./:1:1111B/g; s/[ah][1-8]./:1:1111B/g

    s/[bg][72]./:11:11B/g; s/[c-f][3-6]/:11:11B/g

    s/[a-h][1-9]./:1:11111111B/g

    G; s/\n/ /

    b @
}

#оценочная функция для позиции чёрной королевы (ферзя)
/@estimate-black-queen()/ {
    h; s/.*Board://; s/ .*$//

    # выделяем ферзя и вражеского короля
    s/[a-h][1-8][^qK]//g

    # если одной из фигур на поле нет, возврат
    /....../ ! {
        g; b @
    }

    # фигуры убираем, координаты к числам
    y/abcdefgh/12345678/; s/\([1-9]\)\(.\)./\1 \2 /g

    # группируем координаты, получится X1 X2 Y1 Y2
    s/\([^ ]\) \([^ ]\) \([^ ]\)/\1 \3 \2/

    # переводим координаты в последовательности длины значений координат
    :estimate-black-queen::xy
    /[2-8]/ {
        s/[2-8]/1&/g
        y/2345678/1234567/

        b estimate-black-queen::xy
    }        
    # сортировка — бо́льшая координата вперёд
    s/\(11*\) \(11*\1\)/\2 \1/g

    # вычитаем вторую координату из первой
    s/\(11*\)\(1*\) \1/\2/g

    # умножаем Y-координату на 8
    :estimate-black-queen::mul8
    / 1/ {
        s//88888888 /g
        b estimate-black-queen::mul8
    }
    y/8/1/

    # умножаем получившийся коэффициент на 4
    s/1/1111/g
    # группируем десятки и сотни, тысячи не нужны, максимальная оценка —
    # меньше 300
    s/1111111111/D/g; s/DDDDDDDDDD/H/g; s/\(.\)\1*/&:/g; s/[ :]*$//; y/HD/11/

    G; s/\n/B /

    b @
}

# суммированние чисел на стеке, пока не встретится слово ARRAY
/@sum-array()/ {
    h
    /ARRAY.*/ {
        s///

        s/$/ ::::S/

        :sum-array::shift
        /[1:][1:]*B/ {
            # сложение разряда
            :sum-array::sum
            /11*B/ {
                s/\(11*\)B\(.*\)\(1*\)S/B\2\1\3S/
                s/:1111111111\(1*\)S/1:\1S/

                b sum-array::sum
            }

            # сдвиг разряда
            s/:B/B/g; s/:\(1*\)S/S \1:/

            b sum-array::shift
        }

        s/:\(1*\)S/S \1:/; s/[^1:]//g
        G; s/:*\n.*ARRAY/B /
    }
    b @
}

# выбор указанной фигуры (вернётся в виде строки)
# XYF__XYF__ где F — наименование фигуры, __ — место под перебор позиции
/@select-figures(.)/ {
    h
    # убираем из данных всё лишнее, параметр помечаем маркером
    s/@select-figures(\(.\))\(.*\)/\2 Selected:\1/
    s/.*Board://
    s/ .*Selected:/ Selected:/

    # выделяем из доски то, что указал пользователь
    :select-figures::select
    /\([a-h][0-9]\)\(.\)\(.* Selected:\2\)/ {
        s//\3\1\2__/
        b select-figures::select
    }

    # убираем маркер и изувеченную доску
    s/.*Selected:.//

    # возвращаем стек назад
    G; s/\n/END /
    b @
}

/@iter-knight()/ {
    # убираем коня, который ход закончил
    s/^...XX//
    # выходим, если ходить нечем
    /^END/ b @

    # выделяем первого коня
    h; s/\(.....\).*/\1/

    # кодировка ходов: __ — не был сделан, XX — сделаны все возможные
    # Left, Down, Up, Right, первым пишется ход на две клетки, например:
    # LU — влево на две, вверх на одну

    /__/ {
        s//LU/
        # сдвигаем координату X-2, Y+1, 0 — признак, что ход невозможен
        y/abcdefgh/00abcdef/
        y/12345678/23456780/

        b iter-knight::go
    }

    /LU/ {
        s//UL/
        # X-1, Y+2
        y/abcdefgh/0abcdefg/
        y/12345678/34567800/

        b iter-knight::go
    }

    /UL/ {
        s//UR/
        # X+1, Y+2
        y/abcdefgh/bcdefgh0/
        y/12345678/34567800/

        b iter-knight::go
    }

    /UR/ {
        s//RU/
        # X+2, Y+1
        y/abcdefgh/cdefgh00/
        y/12345678/23456780/

        b iter-knight::go
    }

    /RU/ {
        s//RD/
        # X+2, Y-1
        y/abcdefgh/cdefgh00/
        y/12345678/01234567/

        b iter-knight::go
    }

    /RD/ {
        s//DR/
        # X+1, Y-2
        y/abcdefgh/bcdefgh0/
        y/12345678/00123456/

        b iter-knight::go
    }

    /DR/ {
        s//DL/
        # X-1, Y-2
        y/abcdefgh/0abcdefg/
        y/12345678/00123456/

        b iter-knight::go
    }

    /DL/ {
        s//XX/
        # X-2, Y-1
        y/abcdefgh/00abcdef/
        y/12345678/01234567/

        b iter-knight::go
    }

    :iter-knight::go

    # возвращаем стек
    G; s/\n//
    # переписываем куда мы уже ходили в текущую фигуру
    # XYFPPXYF.. → XYF__XYPP
    s/\(...\)\(..\)\(...\)../\1__\3\2/

    # данные о фигурах и доска, остальное убираем
    s/^\([^ ]*END\).*\(Board:[^ ]*\).*/\1 \2/
    # смотрим нет ли на предполагаемом поле нашей собственной фигуры
    s/^\(..\)\(.*\1[pqkbnr]\)/00\2/

    # если во второй координате ноль, ставим ноль и в первую
    s/^.0/00/

    # если ходить сюда можно, ходим
    /^0/ ! {
        # XY Фигура хода XY Фигура текущая
        # меняем координаты фигуры, которая ходит
        s/\(...\)__\(...\)\(.*Board:.*\)\2/\1__\2\3\1/
        # меняем координаты того места куда ходим
        s/\(..\)\(.__\)\(..\)\(.*Board:.*\)\1\([^n]\)/\1\2\3\4\3\5/
    }

    # стек возвращаем, убирая с него второй (оставшийся) стек выделенных фигур
    G; s/\n[^ ]* */ /
    # меняем нашу добавленную и последнюю доску местами
    s/\(Board:[^ ]*\)\(.*\)\(Board:[^ ]*\)/\3\2\1/

    b @
}

# перемещаем позицию и сумму в конец стека,
# перекладываем счётчик позиции фигуры
/@store-iter()/ {
    # если ходить было нельзя, вычищаем мусор
    /^[^ ]* *0..../ {
        s///
        b @
    }

    # (оценка позиции) (фигура хода) счётчик позиции (текущая фигура) всё остальное →
    # текущая фигура, всё остальное, сумма, ход откуда→ход куда
    s/\([^ ]*\) *\(...\)..\(...\)\([^ ]*END *.*\)/\3\4 \1(\3→\2)/
    b @
}

# вычисление лучшего хода из указанных
/@find-best-move()/ {
    # убираем лишнее
    h; s/[1:][1:]*B/Moves:&/; s/.*Moves:/ /; y/B/:/

    :find-best-move::cut
    # смотрим, есть ли числа с непустым старшим разрядом
    / 1/ {
        # если есть, то убираем те, у которых страший разряд пустой
        s/ :[^ ]*//g
        # теперь отрезаем у каждого по одной цифре старшего разряда
        s/ 1/ /g
        b find-best-move::cut
    }
    # переход через разряд, есть ли ещё числа с разрядами?
    s/ :/ /g
    /:/ b find-best-move::cut

    # если было несколько максимумов, оставляем только первый
    s/^ *\([^ ]*\).*/\1/

    # возвращаем данные на основной стек
    G; s/\n/ /
    # убираем оттуда вычисленные оценки (они у нас в конце стека)
    s/ *[1:][1:]*B.*//

    # теперь на стеке запись вида (XYF→XYF), либо такой записи вообще нет (если не было возможных ходов у фигуры)
    b @
}

# просчёт ходов пешки. На стеке должны быть: начальная оценка по пешкам
# (сюда будет складываться максимум) и выписаны все пешки
# чёрные пешки умеют ходить по 4м направлениям:
# 1) на 1 ход (D1)
# 2) на 2 до середины доски, если поле перед ней не занято (D2)
# 3) вниз влево, если там чужая фигура (DL)
# 4) вниз вправо, если там чужая фигура (DR)
# кроме того, пешка, достигая края доски, имеет право превратиться в любую фигуру (кроме короля)



/@ *$/ {
    q
}

b @