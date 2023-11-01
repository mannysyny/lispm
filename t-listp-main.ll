@.open_mode = private unnamed_addr constant [2 x i8] c"w\00"

declare i8* @fopen(i8* nocapture, i8* nocapture) nounwind
declare i32 @putchar(i32) nounwind

%object = type opaque

declare void @init() nounwind
declare %object* @evalFile(i8*)
declare void @print(%object*)

define i32 @main(i32 %argc, i8** %argv) {
    %arg1Ptr = getelementptr i8*, i8** %argv, i64 1
    %arg1Addr = load i8*, i8** %arg1Ptr

    %cast_open_mode = getelementptr [2 x i8], [2 x i8]* @.open_mode, i64 0, i64 0
    %output = call i8* @fopen(i8* %arg1Addr, i8* %cast_open_mode)

    call void @init()

    %result = call %object* @evalFile(i8* %output)
    call void @print(%object* %result)
    call i32 @putchar(i32 10)

    ret i32 0
}
