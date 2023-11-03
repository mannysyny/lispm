@.open_mode = private unnamed_addr constant [3 x i8] c"r\00"

declare i8* @fopen(i8* nocapture, i8* nocapture) nounwind
declare i32 @fgets(i8* nocapture, i32, i8* nocapture) nounwind
declare i32 @puts(i8* nocapture) nounwind

define i32 @main(i32 %argc, i8** %argv) {
    %filename = getelementptr inbounds i8*, i8** %argv, i32 1
    %file = call i8* @fopen(i8* %filename, i8* getelementptr inbounds ([3 x i8], [3 x i8]* @.open_mode, i32 0, i32 0))

    %buffer = alloca [256 x i8]
    %line = getelementptr inbounds [256 x i8], [256 x i8]* %buffer, i32 0, i32 0
    %line_length = call i32 @fgets(i8* %line, i32 256, i8* %file)
    br label %loop

loop:
    %line_end = getelementptr inbounds [256 x i8], [256 x i8]* %buffer, i32 0, i32 %line_length
    %line_end_minus_one = getelementptr inbounds i8, i8* %line_end, i32 -2
    %line_end_char = load i8, i8* %line_end_minus_one
    %is_end_of_line = icmp eq i8 %line_end_char, 10
    br i1 %is_end_of_line, label %print_line, label %read_line

print_line:
    %line_begin = getelementptr inbounds [256 x i8], [256 x i8]* %buffer, i32 0, i32 0
    call i32 @puts(i8* %line_begin)
    br label %read_line

read_line:
    %line = getelementptr inbounds [256 x i8], [256 x i8]* %buffer, i32 0, i32 0
    %line_length = call i32 @fgets(i8* %line, i32 256, i8* %file)
    %is_end_of_file = icmp eq i32 %line_length, -1
    br i1 %is_end_of_file, label %exit, label %loop

exit:
    ret i32 0
}

@.hello_world = private unnamed_addr constant [14 x i8] c"Hello, world!\0A\00"
