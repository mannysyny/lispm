@.open_mode = private unnamed_addr constant [2 x i8] c"r\00"

declare i8* @fopen(i8* nocapture, i8* nocapture) nounwind
declare i32 @putchar(i32) nounwind

%object = type opaque

declare void @init() nounwind
declare %object* @read(i8*) nounwind
declare %object* @eval(%object*) nounwind
declare void @print(%object*)

define i32 @main(i32 %argc, i8** %argv) {
    call void @init()

    %arg1Ptr = getelementptr i8*, i8** %argv, i64 1
    %arg1Addr = load i8*, i8** %arg1Ptr

    %cast_open_mode = getelementptr [2 x i8], [2 x i8]* @.open_mode, i64 0, i64 0
    %input = call i8* @fopen(i8* %arg1Addr, i8* %cast_open_mode)

    %token = call %object* @read(i8* %input)
    %result = call %object* @eval(%object* %token)
    call void @print(%object* %result)
    call i32 @putchar(i32 10)

    ret i32 0
}
