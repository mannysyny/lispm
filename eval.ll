; Define the syntax tree data structure
%Value = type { i32, i8*, i32*, %Value*, %Value* }

; Define the built-in functions
declare %Value* @add(%Value*, %Value*)
declare %Value* @sub(%Value*, %Value*)
declare %Value* @mul(%Value*, %Value*)
declare %Value* @div(%Value*, %Value*)

; Define the parser function
define %Value* @parse(i8* %input) {
    ; Convert the input string to a list of tokens
    %tokens = call %Value* @tokenize(%input)

    ; Parse the tokens into an abstract syntax tree
    %ast = call %Value* @parse_tokens(%tokens)

    ; Return the abstract syntax tree
    ret %Value* %ast
}

; Define the tokenize function
define %Value* @tokenize(i8* %input) {
    ; Allocate memory for the list of tokens
    %tokens = call %Value* @alloc_list()

    ; Initialize the current token buffer
    %token_buf = call %Value* @alloc_string(16)
    %token_buf_len = alloca i32
    store i32 0, %token_buf_len

    ; Loop over the input string
    %i = alloca i32
    store i32 0, %i
    br label %loop

loop:
    ; Get the current character
    %c = getelementptr inbounds i8, i8* %input, i32 0
    %c = load i8, i8* %c

    ; Check if the current character is whitespace
    %is_whitespace = call i1 @is_whitespace(i8 %c)
    br i1 %is_whitespace, label %skip_char, label %process_char

skip_char:
    ; If the current character is whitespace, skip it
    %input = getelementptr inbounds i8, i8* %input, i32 1
    br label %loop

process_char:
    ; If the current character is not whitespace, append it to the current token buffer
    %token_buf_len_val = load i32, i32* %token_buf_len
    %token_buf_ptr = getelementptr inbounds i8, i8* %token_buf, i32 %token_buf_len_val
    store i8 %c, i8* %token_buf_ptr
    %token_buf_len_val = add i32 %token_buf_len_val, 1
    store i32 %token_buf_len_val, i32* %token_buf_len

    ; Check if the current character is a delimiter
    %is_delimiter = call i1 @is_delimiter(i8 %c)
    br i1 %is_delimiter, label %add_token, label %skip_char

add_token:
    ; If the current character is a delimiter, add the current token to the list of tokens
    %token_buf_len_val = load i32, i32* %token_buf_len
    %token = call %Value* @alloc_string(%token_buf_len_val)
    %token_ptr = extractvalue %Value* %token, 1
    %token_buf_ptr = getelementptr inbounds i8, i8* %token_buf, i32 0
    call void @memcpy(i8* %token_ptr, i8* %token_buf_ptr, i32 %token_buf_len_val, i1 false)
    %tokens = call %Value* @cons(%token, %tokens)

    ; Reset the current token buffer
    %token_buf = call %Value* @alloc_string(16)
    store i32 0, %token_buf_len

    ; Check if we've reached the end of the input string
    %input_len = call i32 @strlen(i8* %input)
    %i_val = load i32, i32* %i
    %is_end = icmp eq i32 %i_val, %input_len
    br i1 %is_end, label %done, label %next_char

next_char:
    ; If we haven't reached the end of the input string, move to the next character
    %i_val = add i32 %i_val, 1
    store i32 %i_val, %i
    %input = getelementptr inbounds i8, i8* %input, i32 1
    br label %loop

done:
    ; Add the final token to the list of tokens
    %token_buf_len_val = load i32, i32* %token_buf_len
    %token = call %Value* @alloc_string(%token_buf_len_val)
    %token_ptr = extractvalue %Value* %token, 1
    %token_buf_ptr = getelementptr inbounds i8, i8* %token_buf, i32 0
    call void @memcpy(i8* %token_ptr, i8* %token_buf_ptr, i32 %token_buf_len_val, i1 false)
    %tokens = call %Value* @cons(%token, %tokens)

    ; Reverse the list of tokens
    %tokens = call %Value* @reverse(%tokens)

    ; Return the list of tokens
    ret %Value* %tokens
}

; Define the parse_tokens function
define %Value* @parse_tokens(%Value* %tokens) {
    ; Allocate memory for the stack
    %stack = call %Value* @alloc_list()

    ; Loop over the tokens
    %current_token = extractvalue %Value* %tokens, 1
    br label %loop

loop:
    ; Check if we've reached the end of the token list
    %is_end = call i1 @is_nil(%Value* %current_token)
    br i1 %is_end, label %done, label %process_token

process_token:
    ; Get the type of the current token
    %token_type = call i32 @get_token_type(%Value* %current_token)

    ; Check if the current token is a number
    %is_number = icmp eq i32 %token_type, 0
    br i1 %is_number, label %push_number, label %not_number

push_number:
    ; If the current token is a number, push it onto the stack
    %value = call %Value* @parse_number(%Value* %current_token)
    %stack = call %Value* @cons(%value, %stack)
    %tokens = extractvalue %Value* %tokens, 2
    %current_token = extractvalue %Value* %tokens, 1
    br label %loop

not_number:
    ; If the current token is not a number, it must be an operator or a list
    %is_operator = icmp eq i32 %token_type, 1
    br i1 %is_operator, label %push_operator, label %push_list

push_operator:
    ; If the current token is an operator, push it onto the stack
    %value = call %Value* @parse_operator(%Value* %current_token)
    %stack = call %Value* @cons(%value, %stack)
    %tokens = extractvalue %Value* %tokens, 2
    %current_token = extractvalue %Value* %tokens, 1
    br label %loop

push_list:
    ; If the current token is a list, parse it and push it onto the stack
    %value = call %Value* @parse_list(%Value* %tokens)
    %stack = call %Value* @cons(%value, %stack)
    %tokens = extractvalue %Value* %tokens, 2
    %current_token = extractvalue %Value* %tokens, 1
    br label %loop

done:
    ; Pop the final value off the stack
    %value = call %Value* @car(%stack)

    ; Check if there are any remaining values on the stack
    %is_empty = call i1 @is_nil(%Value* %value)
    br i1 %is_empty, label %return_nil, label %return_value

return_nil:
    ; If there are no remaining values on the stack, return nil
    ret %Value* null

return_value:
    ; If there are remaining values on the stack, return the first value
    ret %Value* %value
}

; Define the is_whitespace function
define i1 @is_whitespace(i8 %c) {
    ; Check if the character is whitespace
    %is_space = icmp eq i8 %c, 32
    %is_tab = icmp eq i8 %c, 9
    %is_newline = icmp eq i8 %c, 10
    %is_return = icmp eq i8 %c, 13
    %is_whitespace = or i1 %is_space, %is_tab
    %is_whitespace = or i1 %is_whitespace, %is_newline
    %is_whitespace = or i1 %is_whitespace, %is_return
    ret i1 %is_whitespace
}

; Define the is_delimiter function
define i1 @is_delimiter(i8 %c) {
    ; Check if the character is a delimiter
    %is_space = icmp eq i8 %c, 32
    %is_tab = icmp eq i8 %c, 9
    %is_newline = icmp eq i8 %c, 10
    %is_return = icmp eq i8 %c, 13
    %is_open_paren = icmp eq i8 %c, 40
    %is_close_paren = icmp eq i8 %c, 41
    %is_delimiter = or i1 %is_space, %is_tab
    %is_delimiter = or i1 %is_delimiter, %is_newline
    %is_delimiter = or i1 %is_delimiter, %is_return
    %is_delimiter = or i1 %is_delimiter, %is_open_paren
    %is_delimiter = or i1 %is_delimiter, %is_close_paren
    ret i1 %is_delimiter
}

; Define the get_token_type function
define i32 @get_token_type(%Value* %token) {
    ; Get the first character of the token
    %token_ptr = extractvalue %Value* %token, 1
    %c = load i8, i8* %token_ptr

    ; Check if the first character is a digit
    %is_digit = icmp ult i8 48, %c
    %is_digit = and i1 %is_digit, icmp ule i8 %c, 57
    br i1 %is_digit, label %number, label %not_number

number:
    ; If the first character is a digit, the token is a number
    ret i32 0

not_number:
    ; If the first character is not a digit, the token is an operator or a list
    %is_open_paren = icmp eq i8 %c, 40
    %is_close_paren = icmp eq i8 %c, 41
    %is_operator = or i1 %is_open_paren, %is_close_paren
    br i1 %is_operator, label %operator, label %list

operator:
    ; If the first character is an operator, the token is an operator
    ret i32 1

list:
    ; If the first character is not an operator, the token is a list
    ret i32 2
}

; Define the parse_number function
define %Value* @parse_number(%Value* %token) {
    ; Get the string value of the token
    %token_ptr = extractvalue %Value* %token, 1
    %token_len = extractvalue %Value* %token, 2
    %str = call i8* @alloc_string(%token_len)
    call void @memcpy(i8* %str, i8* %token_ptr, i32 %token_len, i1 false)

    ; Parse the string value as a number
    %value = call %Value* @alloc_number(i8* %str)

    ; Return the number value
    ret %Value* %value
}

; Define the parse_operator function
define %Value* @parse_operator(%Value* %token) {
    ; Get the string value of the token
    %token_ptr = extractvalue %Value* %token, 1
    %token_len = extractvalue %Value* %token, 2
    %str = call i8* @alloc_string(%token_len)
    call void @memcpy(i8* %str, i8* %token_ptr, i32 %token_len, i1 false)

    ; Parse the string value as an operator
    %value = call %Value* @alloc_operator(i8* %str)

    ; Return the operator value
    ret %Value* %value
}

; Define the parse_list function
define %Value* @parse_list(%Value* %tokens) {
    ; Allocate memory for the list
    %list = call %Value* @alloc_list()

    ; Loop over the tokens
    %current_token = extractvalue %Value* %tokens, 1
    br label %loop

loop:
    ; Check if we've reached the end of the token list
    %is_end = call i1 @is_nil(%Value* %current_token)
    br i1 %is_end, label %done, label %process_token

process_token:
    ; Parse the current token and add it to the list
    %value = call %Value* @parse_tokens(%tokens)
    %list = call %Value* @cons(%value, %list)
    %tokens = extractvalue %Value* %tokens, 2
    %current_token = extractvalue %Value* %tokens, 1
    br label %loop

done:
    ; Reverse the list and return it
    %list = call %Value* @reverse(%list)
    ret %Value* %list
}

; Define the is_nil function
define i1 @is_nil(%Value* %value) {
    ; Check if the value is nil
    %is_nil = icmp eq %Value* %value, null
    ret i1 %is_nil
}

; Define the strlen function
declare i32 @strlen(i8*)

; Define the memcpy function
declare void @memcpy(i8*, i8*, i32, i1)

; Define the alloc_string function
define i8* @alloc_string(i32 %len) {
    ; Allocate memory for the string
    %str = call i8* @malloc(i32 add %len, 1)

    ; Zero out the memory
    call void @memset(i8* %str, i8 0, i32 add %len, i1 false)

    ; Return the string pointer
    ret i8* %str
}

; Define the alloc_number function
define %Value* @alloc_number(i8* %str) {
    ; Allocate memory for the number value
    %value = call %Value* @malloc(i32 sizeof(%Value))

    ; Set the type tag to 0 (number)
    %type_tag = getelementptr %Value, %Value* %value, i32 0, i32 0
    store i32 0, i32* %type_tag

    ; Set the number value
    %number = call i32 @atoi(i8* %str)
    %number_ptr = getelementptr %Value, %Value* %value, i32 0, i32 2
    store i32 %number, i32* %number_ptr

    ; Return the number value
    ret %Value* %value
}

; Define the alloc_operator function
define %Value* @alloc_operator(i8* %str) {
    ; Allocate memory for the operator value
    %value = call %Value* @malloc(i32 sizeof(%Value))

    ; Set the type tag to 3 (operator)
    %type_tag = getelementptr %Value, %Value* %value, i32 0, i32 0
    store i32 3, i32* %type_tag

    ; Set the operator value
    %operator_ptr = getelementptr %Value, %Value* %value, i32 0, i32 1
    store i8* %str, i8** %operator_ptr

    ; Return the operator value
    ret %Value* %value
}

; Define the alloc_list function
define %Value* @alloc_list() {
    ; Allocate memory for the list value
    %value = call %Value* @malloc(i32 sizeof(%Value))

    ; Set the type tag to 2 (list)
    %type_tag = getelementptr %Value, %Value* %value, i32 0, i32 0
    store i32 2, i32* %type_tag

    ; Set the head and tail pointers to nil
    %head_ptr = getelementptr %Value, %Value* %value, i32 0, i32 3
    store %Value* null, %Value** %head_ptr
    %tail_ptr = getelementptr %Value, %Value* %value, i32 0, i32 4
    store %Value* null, %Value** %tail_ptr

    ; Return the list value
    ret %Value* %value
}

; Define the cons function
define %Value* @cons(%Value* %head, %Value* %tail) {
    ; Allocate memory for the cons cell
    %cell = call %Value* @malloc(i32 sizeof(%Value))

    ; Set the type tag to 2 (list)
    %type_tag = getelementptr %Value, %Value* %cell, i32 0, i32 0
    store i32 2, i32* %type_tag

    ; Set the head and tail pointers
    %head_ptr = getelementptr %Value, %Value* %cell, i32 0, i32 3
    store %Value* %head, %Value** %head_ptr
    %tail_ptr = getelementptr %Value, %Value* %cell, i32 0, i32 4
    store %Value* %tail, %Value** %tail_ptr

    ; Return the cons cell
    ret %Value* %cell
}

; Define the car function
define %Value* @car(%Value* %list) {
    ; Get the head of the list
    %head_ptr = getelementptr %Value, %Value* %list, i32 0, i32 3
    %head = load %Value*, %Value** %head_ptr

    ; Return the head of the list
    ret %Value* %head
}

; Define the cdr function
define %Value* @cdr(%Value* %list) {
    ; Get the tail of the list
    %tail_ptr = getelementptr %Value, %Value* %list, i32 0, i32 4
    %tail = load %Value*, %Value** %tail_ptr

    ; Return the tail of the list
    ret %Value* %tail
}

; Define the reverse function
define %Value* @reverse(%Value* %list) {
    ; Allocate memory for the reversed list
    %reversed = call %Value* @alloc_list()

    ; Loop over the list
    br label %loop

loop:
    ; Check if we've reached the end of the list
    %is_end = call i1 @is_nil(%Value* %list)
    br i1 %is_end, label %done, label %process_cell

process_cell:
    ; Get the head and tail of the current cell
    %head = call %Value* @car(%list)
    %tail = call %Value* @cdr(%list)

    ; Add the head to the beginning of the reversed list
    %reversed = call %Value* @cons(%head, %reversed)

    ; Move to the next cell
    %list = %tail
    br label %loop

done:
    ; Return the reversed list
    ret %Value* %reversed
}

; Define the malloc function
declare i8* @malloc(i32)

; Define the memset function
declare void @memset(i8*, i8, i32, i1)

; Define the atoi function
declare i32 @atoi(i8*)
    ; Define the evaluator function
    define %Value* @eval(%Value* %expr, %Value* %env) {
        ; Get the type tag of the expression
        %type_tag = extractvalue %Value* %expr, 0

        ; Check if the expression is a number
        %is_number = icmp eq i32 %type_tag, 0
        br i1 %is_number, label %number, label %not_number

    number:
        ; If the expression is a number, return it
        ret %Value* %expr

    not_number:
        ; Check if the expression is a symbol
        %is_symbol = icmp eq i32 %type_tag, 1
        br i1 %is_symbol, label %symbol, label %not_symbol

    symbol:
        ; If the expression is a symbol, look it up in the environment
        %name_ptr = extractvalue %Value* %expr, 1
        %name = load i8*, i8** %name_ptr
        %value_ptr = call %Value* @lookup(%Value* %env, i8* %name)
        ret %Value* %value_ptr

    not_symbol:
        ; Check if the expression is a list
        %is_list = icmp eq i32 %type_tag, 2
        br i1 %is_list, label %list, label %not_list

    list:
        ; If the expression is a list, evaluate it
        %head_ptr = extractvalue %Value* %expr, 3
        %head = load %Value*, %Value** %head_ptr
        %tail_ptr = extractvalue %Value* %expr, 4
        %tail = load %Value*, %Value** %tail_ptr
        %head_value_ptr = call %Value* @eval(%Value* %head, %Value* %env)
        %tail_value_ptr = call %Value* @eval(%Value* %tail, %Value* %env)
        %head_value = load %Value*, %Value** %head_value_ptr
        %tail_value = load %Value*, %Value** %tail_value_ptr

        ; Get the type tag of the head value
        %head_type_tag = extractvalue %Value* %head_value, 0

        ; Check if the head value is a built-in function
        %is_builtin = icmp eq i32 %head_type_tag, 3
        br i1 %is_builtin, label %builtin, label %not_builtin

    not_builtin:
        ; If the head value is not a built-in function, it must be a user-defined function
        %params_ptr = extractvalue %Value* %head_value, 2
        %body_ptr = extractvalue %Value* %head_value, 3
        %new_env = call %Value* @extend_env(%Value* %env, %Value* %params_ptr, %Value* %tail_value_ptr)
        ret %Value* call %Value* @eval(%Value* %body_ptr, %Value* %new_env)

    builtin:
        ; If the head value is a built-in function, call it with the tail value
        %result_ptr = call %Value* @call_builtin(%Value* %head_value, %Value* %tail_value)
        ret %Value* %result_ptr

        ; Define the lookup function
        declare %Value* @lookup(%Value*, i8*)

        ; Define the extend_env function
        declare %Value* @extend_env(%Value*, %Value*, %Value*)

        ; Define the call_builtin function
        declare %Value* @call_builtin(%Value*, %Value*)
    }
}

; Define the error handling functions
define void @error(i8* %message) {
define void @syntax_error(i8* %message) {
    ; Print the error message
    %format_str = getelementptr inbounds [15 x i8], [15 x i8]* @syntax_error_fmt, i32 0, i32 0
    call i32 (i8*, ...) @printf(i8* %format_str, i8* %message)

    ; Exit the program with an error code
    call void @exit(i32 1)
    unreachable
}

define void @runtime_error(i8* %message) {
    ; Print the error message
    %format_str = getelementptr inbounds [16 x i8], [16 x i8]* @runtime_error_fmt, i32 0, i32 0
    call i32 (i8*, ...) @printf(i8* %format_str, i8* %message)

    ; Exit the program with an error code
    call void @exit(i32 1)
    unreachable
}

@syntax_error_fmt = private unnamed_addr constant [15 x i8] c"%s: syntax error\0A\00"
@runtime_error_fmt = private unnamed_addr constant [16 x i8] c"%s: runtime error\0A\00"
}

define void @syntax_error(i8* %message) {
    ; Call the syntax error function with the error message
    call void @syntax_error(i8* %error_message)
}

define void @runtime_error(i8* %message) {
    ; TODO: Implement the runtime error handling
    ; Define the error handling functions
    define void @error(i8* %message) {
        ; Print the error message
        %format_str = getelementptr inbounds [8 x i8], [8 x i8]* @error_fmt, i32 0, i32 0
        call i32 (i8*, ...) @printf(i8* %format_str, i8* %message)

        ; Exit the program with an error code
        call void @exit(i32 1)
        unreachable
    }

    define void @syntax_error(i8* %message) {
        ; Print the error message
        %format_str = getelementptr inbounds [15 x i8], [15 x i8]* @syntax_error_fmt, i32 0, i32 0
        call i32 (i8*, ...) @printf(i8* %format_str, i8* %message)

        ; Exit the program with an error code
        call void @exit(i32 1)
        unreachable
    }

    define void @runtime_error(i8* %message) {
        ; Print the error message
        %format_str = getelementptr inbounds [16 x i8], [16 x i8]* @runtime_error_fmt, i32 0, i32 0
        call i32 (i8*, ...) @printf(i8* %format_str, i8* %message)

        ; Exit the program with an error code
        call void @exit(i32 1)
        unreachable
    }

    @error_fmt = private unnamed_addr constant [8 x i8] c"Error: %s\0A\00"
    @syntax_error_fmt = private unnamed_addr constant [15 x i8] c"%s: syntax error\0A\00"
    @runtime_error_fmt = private unnamed_addr constant [16 x i8] c"%s: runtime error\0A\00"
}
