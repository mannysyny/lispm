@.open_mode = private unnamed_addr constant [3 x i8] c"w\00a\00"

declare i8* @fopen(i8* nocapture, i8* nocapture) nounwind
declare i32 @putchar(i32) nounwind

%object = type opaque

declare void @init_reader()
declare void @init_eval()

declare %object* @read(i8*)
declare %object* @eval(%object*)
declare void @print(%object*)

define void @init() {
    call void @init_reader()
    call void @init_eval()
    ret void
}

; Evaluates the contents of a file
define void @evalFile(i8* %input) {
    %file = call i8* @fopen(i8* %input, i8* getelementptr inbounds ([3 x i8], [3 x i8]* @.open_mode, i32 0, i32 0))
    %eof = icmp eq i8* %file, null
    br i1 %eof, label %close_file, label %read_eval

read_eval:
    %line = call i8* @fgets(i8* null, i32 0, i8* %file)
    %is_eof = icmp eq i8* %line, null
    br i1 %is_eof, label %close_file, label %eval_line

eval_line:
    %token = call %object* @read(i8* %line)
    %is_eof = icmp eq %object* null, %token
    br i1 %is_eof, label %read_eval, label %eval_token

eval_token:
    %result = call %object* @eval(%object* %token)
    call void @print(%object* %result)
    br label %read_eval

close_file:
    call i32 @fclose(i8* %file)
    ret void
}
