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

    ; Check if the user provided a file name
    %arg1Ptr = getelementptr i8*, i8** %argv, i64 1
    %arg1Addr = load i8*, i8** %arg1Ptr
    %isNull = icmp eq i8* %arg1Addr, null
    br i1 %isNull, label %noFileProvided, label %fileProvided

    ; If no file name was provided, print an error message and exit
    noFileProvided:
        %errorMsg = getelementptr [23 x i8], [23 x i8]* @.no_file_error, i64 0, i64 0
        call i32 (i8*, ...) @printf(i8* %errorMsg)
        call i32 @putchar(i32 10)
        ret i32 1

    ; If a file name was provided, open the file and start processing
    fileProvided:
        %cast_open_mode = getelementptr [2 x i8], [2 x i8]* @.open_mode, i64 0, i64 0
        %input = call i8* @fopen(i8* %arg1Addr, i8* %cast_open_mode)

        %token = call %object* @read(i8* %input)
        %result = call %object* @eval(%object* %token)
        call void @print(%object* %result)
        call i32 @putchar(i32 10)

        ; Close the file
        call i32 @fclose(i8* %input)

        ret i32 0
}

@.no_file_error = private unnamed_addr constant [23 x i8] c"No file name provided.\0A\00"
