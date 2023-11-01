@.open_mode = private unnamed_addr constant [3 x i8] c"w\00"

declare i8* @fopen(i8* nocapture, i8* nocapture) nounwind
declare i32 @fputs(i8* nocapture, i8* nocapture) nounwind
declare i32 @putchar(i32) nounwind

define i32 @main(i32 %argc, i8** %argv) {
    %filename = getelementptr inbounds i8*, i8** %argv, i32 1
    %file = call i8* @fopen(i8* %filename, i8* getelementptr inbounds ([3 x i8], [3 x i8]* @.open_mode, i32 0, i32 0))

    %message = getelementptr inbounds [14 x i8], [14 x i8]* @.hello_world, i32 0, i32 0
    call i32 @fputs(i8* %message, i8* %file)

    call i32 @putchar(i32 10)
    ret i32 0
}

@.hello_world = private unnamed_addr constant [14 x i8] c"Hello, world!\00"
