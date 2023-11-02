declare i8* @malloc(i32) nounwind
declare i32 @printf(i8*, ...) nounwind

; Tag values:
; 0 - List
; 1 - Token
; 2 - Native Function
%object = type {
     i32,  ; Tag
     i8*   ; Value (may be bitcast, if it safely fits in a pointer)
}

define %object* @createObject(i32 %tag, i8* %val) {
    %objectSize = sizeof %object
    %objSpace = call i8* @malloc(i32 %objectSize)
    %objPtr = bitcast i8* %objSpace to %object*

    %tagPtr = getelementptr inbounds %object, %object* %objPtr, i32 0, i32 0
    store i32 %tag, i32* %tagPtr

    %valPtr = getelementptr inbounds %object, %object* %objPtr, i32 0, i32 1
    store i8* %val, i8** %valPtr

    ret %object* %objPtr
}

define i32 @getTag(%object* %obj) {
    %tagPtr = getelementptr inbounds %object, %object* %obj, i32 0, i32 0
    %tag = load i32, i32* %tagPtr
    ret i32 %tag
}

define i8* @getValue(%object* %obj) {
    %valPtr = getelementptr inbounds %object, %object* %obj, i32 0, i32 1
    %val = load i8*, i8** %valPtr
    ret i8* %val
}

define void @printObject(%object* %obj) {
    %tag = call i32 @getTag(%object* %obj)
    %val = call i8* @getValue(%object* %obj)

    %tagStr = select i1 %tag == 0, [4 x i8]* @.str.list, [6 x i8]* @.str.token
    %tagFmt = select i1 %tag == 0, [4 x i8]* @.str.list_fmt, [6 x i8]* @.str.token_fmt

    call i32 (i8*, ...) @printf(i8* %tagFmt, [4 x i8]* %tagStr, i8* %val)
    ret void
}

@.str.list = private unnamed_addr constant [4 x i8] c"List\00"
@.str.token = private unnamed_addr constant [6 x i8] c"Token\00"
@.str.list_fmt = private unnamed_addr constant [7 x i8] c"%s: %p\0A\00"
@.str.token_fmt = private unnamed_addr constant [9 x i8] c"%s: %s\0A\00"
