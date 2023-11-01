@.open_mode = private unnamed_addr constant [2 x i8] c"w\00"
@.prompt = private unnamed_addr constant [ 8 x i8 ] c"lisp> \00"

declare i8* @fopen(i8* nocapture, i8* nocapture) nounwind
declare i8* @fdopen(i32, i8* nocapture) nounwind
declare i32 @putchar(i32) nounwind

%object = type opaque

declare void @init() nounwind
declare %object* @evalFile(i8*)

declare void @printToken(i8*)
declare %object* @read(i8*)
declare %object* @eval(%object*)
declare void @print(%object*)

define i32 @repl(i8* %input) {
    %prompt = getelementptr [8 x i8], [8 x i8]* @.prompt, i64 0, i64 0

    call void @printToken(i8* %prompt)
    %token = call %object* @read(i8* %input)
    %is_eof = icmp eq %object* null, %token
    br i1 %is_eof, label %ret_done, label %eval_token

ret_done:
    call i32 @putchar(i32 10)
    ret i32 0

eval_token:
    %result = call %object* @eval(%object* %token)
    call void @print(%object* %result)
    call i32 @putchar(i32 10)

    %ret = call i32 @repl(i8* %input)
    ret i32 %ret
}

define i32 @main(i32 %argc, i8** %argv) {
    %cast_open_mode = getelementptr [2 x i8], [2 x i8]* @.open_mode, i64 0, i64 0
    call void @init()

    %is_repl = icmp eq i32 1, %argc
    br i1 %is_repl, label %repl, label %file

repl:
    %stdinInput = call i8* @fdopen(i32 0, i8* %cast_open_mode)
    %repl_res = call i32 @repl(i8* %stdinInput)
    ret i32 %repl_res

file:
    %arg1Ptr = getelementptr i8*, i8** %argv, i64 1
    %arg1Addr = load i8*, i8** %arg1Ptr

    %fileInput = call i8* @fopen(i8* %arg1Addr, i8* %cast_open_mode)

    %result = call %object* @evalFile(i8* %fileInput)

    ret i32 0
}
