@.open_mode = private unnamed_addr constant [2 x i8] c"w\00"

declare i8* @fopen(i8* nocapture, i8* nocapture) nounwind
declare i32 @putchar(i32) nounwind

%object = type opaque

declare void @init() nounwind
declare %object* @evalFile(i8*)
declare void @print(%object*)

define i32 @main(i32 %argc, i8** %argv) {
        ; Check if the user provided a file name
        %argCount = icmp eq i32 %argc, 2
        br i1 %argCount, label %openFile, label %printUsage

    openFile:
        ; Open the file
        %arg1Ptr = getelementptr i8*, i8** %argv, i64 1
        %arg1Addr = load i8*, i8** %arg1Ptr
        %cast_open_mode = getelementptr [2 x i8], [2 x i8]* @.open_mode, i64 0, i64 0
        %output = call i8* @fopen(i8* %arg1Addr, i8* %cast_open_mode)

        ; Evaluate the file contents
        call void @init()
        %result = call %object* @evalFile(i8* %output)

        ; Print the result
        call void @print(%object* %result)
        call i32 @putchar(i32 10)

        ; Close the file
        call i32 @fclose(i8* %output)

        ret i32 0

    printUsage:
        ; Print usage message
        %usage = getelementptr [25 x i8], [25 x i8]* @.usage, i64 0, i64 0
        call i32 @puts(i8* %usage)
        ret i32 1

    ; Constants
    @.usage = private unnamed_addr constant [25 x i8] c"Usage: t-listp <filename>\0A\00"
}

declare i32 @fclose(i8*) nounwind
declare i32 @puts(i8*) nounwind
