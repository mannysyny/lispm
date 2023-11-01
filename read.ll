; Define integer constants
@.space = private constant i8 32
@.newline = private constant i8 10
@.macro = private constant i8 39
@.term = private constant i8 41

; Define global variables
@macro_table = global [256 x i8*] zeroinitializer
@list = opaque global %struct.list { %struct.list* null, %struct.object* null }

; Declare external functions
declare i8* @malloc(i32)
declare i32 @feof(i8*)
declare i32 @getc(i8*)
declare i32 @ungetc(i32, i8*)

; Declare custom functions
declare %struct.object* @make_integer(i32)
declare %struct.object* @make_symbol(i8*)
declare %struct.object* @make_cons(%struct.object*, %struct.object*)
declare %struct.object* @make_list(%struct.list*)
declare %struct.object* @make_string(i8*)

; Define opaque types
%struct.list = type { %struct.list*, %struct.object* }
%struct.object = type { i8, i8*, %union.anon }

%union.anon = type { %struct.cons*, %struct.symbol*, %struct.integer*, %struct.string* }
%struct.cons = type { %struct.object*, %struct.object* }
%struct.symbol = type { i8* }
%struct.integer = type { i32 }
%struct.string = type { i8*, i32 }

; Define functions
define i32 @read(i8* %stream, %struct.list** %list) {
entry:
    %1 = call i32 @getc(i8* %stream)
    %2 = icmp eq i32 %1, -1
    br i1 %2, label %eof, label %not_eof

not_eof:
    %3 = trunc i32 %1 to i8
    %4 = icmp eq i8 %3, @.space
    br i1 %4, label %read_space, label %not_space

read_space:
    %5 = call i32 @getc(i8* %stream)
    %6 = icmp eq i32 %5, -1
    br i1 %6, label %eof, label %not_eof

not_space:
    %7 = icmp eq i8 %3, @.newline
    br i1 %7, label %read_newline, label %not_newline

read_newline:
    %8 = call i32 @ungetc(i32 %1, i8* %stream)
    br label %eof

not_newline:
    %9 = icmp eq i8 %3, @.macro
    br i1 %9, label %read_macro, label %not_macro

read_macro:
    %10 = call i32 @getc(i8* %stream)
    %11 = trunc i32 %10 to i8
    %12 = sext i8 %11 to i32
    %13 = getelementptr [256 x i8*], [256 x i8*]* @macro_table, i32 0, i32 %12
    %14 = load i8*, i8** %13
    %15 = call %struct.object* (%struct.list*, i8*, i32) bitcast (i8* %14 to %struct.object* (%struct.list*, i8*, i32)*)(%struct.list* %list, i8* %stream, i32 %11)
    br label %eof

not_macro:
    %16 = icmp eq i8 %3, @.term
    br i1 %16, label %end_list, label %not_term

not_term:
    %17 = call %struct.object* @make_symbol(i8* %stream)
    %18 = call %struct.object* @make_cons(%struct.object* %17, %struct.object* null)
    %19 = call %struct.object* @make_cons(%struct.object* %18, %struct.object* null)
    %20 = call %struct.object* @make_cons(%struct.object* %19, %struct.object* null)
    %21 = call %struct.object* @make_list(%struct.list* %list)
    %22 = call %struct.object* @make_cons(%struct.object* %20, %struct.object* %21)
    br label %eof

eof:
    ret i32 0
}

define %struct.object* @read_list(%struct.list* %list, i8* %stream, i32 %macro) {
entry:
    %1 = call i32 @read(i8* %stream, %struct.list** %list)
    %2 = icmp eq i32 %1, 0
    br i1 %2, label %end_list, label %not_end_list

not_end_list:
    %3 = call %struct.object* @make_cons(%struct.object* %list, %struct.object* null)
    %4 = call %struct.object* @read_list(%struct.list* %list, i8* %stream, i32 %macro)
    %5 = call %struct.object* @make_cons(%struct.object* %4, %struct.object* null)
    %6 = call %struct.object* @make_cons(%struct.object* %5, %struct.object* null)
    br label %end_list

end_list:
    %7 = call %struct.object* @make_cons(%struct.object* %3, %struct.object* null)
    %8 = call %struct.object* @make_list(%struct.list* %list)
    %9 = call %struct.object* @make_cons(%struct.object* %7, %struct.object* %8)
    ret %struct.object* %9
}

define %struct.object* @end_list(%struct.list* %list, i8* %stream, i32 %macro) {
entry:
    %1 = call %struct.object* @make_list(%struct.list* %list)
    ret %struct.object* %1
}

define void @init_reader() {
entry:
    %1 = getelementptr [256 x i8*], [256 x i8*]* @macro_table, i32 0, i32 40
    %2 = bitcast %struct.object* (%struct.list*, i8*, i32)* @read_list to i8*
    store i8* %2, i8** %1
    %3 = getelementptr [256 x i8*], [256 x i8*]* @macro_table, i32 0, i32 41
    %4 = bitcast %struct.object* (%struct.list*, i8*, i32)* @end_list to i8*
    store i8* %4, i8** %3
}
