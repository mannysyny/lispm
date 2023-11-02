; Define the structure of a cons cell
%cons = type { i32, %list* }

; Define the structure of a list node
%list = type { i1, %cons* }

; Define the function to print a list element
define void @printListElem(%list* %node) {
    %consPtr = extractvalue %list %node, 1
    %car = extractvalue %cons %consPtr, 0
    call void @print(i32 %car)
    ret void
}

; Define the function to print a list
define void @printList(%list* %node) {
    ; Handle printing an empty list
    %consPtr = extractvalue %list %node, 1
    %isNull = icmp eq %consPtr, null
    br %isNull, label %printEmptyList, label %printNonEmptyList

printEmptyList:
    call void @printString(i8* getelementptr inbounds ([2 x i8], [2 x i8]* @emptyListString, i32 0, i32 0))
    ret void

printNonEmptyList:
    ; Handle printing a non-empty list
    %cdr = extractvalue %cons %consPtr, 1
    call void @printChar(i8 '(')
    call void @printListElem(%list* %node)
    call void @printChar(i8 ' ')
    call void @printList(%list* %cdr)
    call void @printChar(i8 ')')
    ret void
}

; Define the function to print a string
define void @printString(i8* %str) {
    %len = call i32 @strlen(i8* %str)
    call void @fwrite(i8* %str, i32 1, i32 %len, %FILE*)
    ret void
}

; Define the function to print a character
define void @printChar(i8 %c) {
    call void @fwrite(i8* %c, i32 1, i32 1, %FILE*)
    ret void
}

; Define the function to print an integer
define void @print(i32 %n) {
    %str = call i8* @itoa(i32 %n)
    call void @printString(i8* %str)
    ret void
}

; Define the function to convert an integer to a string
define i8* @itoa(i32 %n) {
    %buf = alloca [11 x i8]
    %i = alloca i32
    store i32 %n, i32* %i
    %p = getelementptr [11 x i8], [11 x i8]* %buf, i32 0, i32 0
    %fmt = getelementptr [4 x i8], [4 x i8]* @intFmt, i32 0, i32 0
    %len = call i32 @sprintf(i8* %p, i8* %fmt, i32* %i)
    %str = call i8* @malloc(i32 %len)
    %p2 = getelementptr [11 x i8], [11 x i8]* %buf, i32 0, i32 0
    %p3 = getelementptr i8, i8* %str, i32 0
    call void @memcpy(i8* %p3, i8* %p2, i32 %len, i1 false)
    ret i8* %str
}

; Define the function to get the length of a string
define i32 @strlen(i8* %str) {
    %p = %str
    %len = i32 0
    br label %loop

loop:
    %c = load i8, i8* %p
    %isNull = icmp eq i8 %c, 0
    br %isNull, label %done, label %next

next:
    %p2 = getelementptr i8, i8* %p, i32 1
    %len2 = add i32 %len, 1
    store i8* %p2, i8** %p
    store i32 %len2, i32* %len
    br label %loop

done:
    ret i32 %len
}

; Define the function to write to a file
define void @fwrite(i8* %ptr, i32 %size, i32 %count, i32 %file) {
    %buf = alloca [4096 x i8]
    %p = getelementptr [4096 x i8], [4096 x i8]* %buf, i32 0, i32 0
    %len = mul i32 %size, %count
    %i = i32 0
    br label %loop

loop:
    %i2 = add i32 %i, 4096
    %len2 = icmp sgt i32 %len, 4096
    %len3 = select i1 %len2, i32 4096, i32 %len
    %p2 = getelementptr i8, i8* %ptr, i32 %i
    call void @memcpy(i8* %p, i8* %p2, i32 %len3, i1 false)
    %i3 = add i32 %i, %len3
    %len4 = sub i32 %len, %len3
    %isNull = icmp eq i32 %len4, 0
    br %isNull, label %done, label %loop

done:
    %p3 = getelementptr [4096 x i8], [4096 x i8]* %buf, i32 0, i32 0
    %len5 = mul i32 %size, %count
    %fwrite = tail call i32 @fwrite(i8* %p3, i32 %size, i32 %len5, i32 %file)
    ret void
}

; Define the function to allocate memory
define i8* @malloc(i32 %size) {
    %p = tail call i8* @malloc(i32 %size)
    ret i8* %p
}

; Define the format string for integers
@intFmt = private unnamed_addr constant [4 x i8] c"%d\00"

; Define the string for an empty list
@emptyListString = private unnamed_addr constant [2 x i8] c"()\00"
