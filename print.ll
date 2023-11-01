; Define the structure of a cons cell
%cons = type { i32, %list* }

; Define the structure of a list node
%list = type { i1, %cons* }

; Define the function to print a list element
define void @printListElem(%list* %node) {
    %isToken = extractvalue %list %node, 0
    %consPtr = extractvalue %list %node, 1
    %isNull = icmp eq %consPtr, null
    br %isNull, label %printToken, label %printCons

printToken:
    ; Handle printing a token
    call void @printToken()
    ret void

printCons:
    ; Handle printing a cons cell
    %car = extractvalue %cons %consPtr, 0
    %cdr = extractvalue %cons %consPtr, 1
    call void @print(i32 %car)
    call void @printList(%list* %cdr)
    ret void
}

; Define the function to print a list
define void @printList(%list* %node) {
    %isNull = icmp eq %node, null
    br %isNull, label %end, label %print

print:
    ; Handle printing a list node
    call void @printListElem(%list* %node)
    %next = extractvalue %list %node, 1
    br label %loop

loop:
    ; Traverse the list recursively
    %isNull = icmp eq %next, null
    br %isNull, label %end, label %print

end:
    ret void
}

; Define the function to print a token
define void @printToken() {
    ; Handle printing a token
    ret void
}

; Define the function to print an integer
define void @print(i32 %val) {
    ; Handle printing an integer
    ret void
}
