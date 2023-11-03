%Token = type { i8*, i32 }

declare i8* @malloc(i64)

define %Token @newObject(i32 %size) {
    %token = alloca %Token
    %data = call i8* @malloc(i64 %size)
    %0 = bitcast i8* %data to i8**
    store i8* %data, i8** %0
    %1 = bitcast i8* %data to i32*
    store i32 %size, i32* %1
    %2 = getelementptr %Token, %Token* %token, i32 0, i32 0
    store i8* %data, i8** %2
    %3 = getelementptr %Token, %Token* %token, i32 0, i32 1
    store i32 %size, i32* %3
    ret %Token %token
}

define void @appendChar(%Token* %token, i8 %char) {
    %data = getelementptr %Token, %Token* %token, i32 0, i32 0
    %size = getelementptr %Token, %Token* %token, i32 0, i32 1
    %current_size = load i32, i32* %size
    %new_size = add i32 %current_size, 1
    %new_data = call i8* @malloc(i64 %new_size)
    %0 = bitcast i8* %new_data to i8**
    store i8* %new_data, i8** %0
    %1 = bitcast i8* %new_data to i8*
    %2 = getelementptr i8, i8* %1, i32 %current_size
    store i8 %char, i8* %2
    %3 = getelementptr %Token, %Token* %token, i32 0, i32 0
    store i8* %new_data, i8** %3
    store i32 %new_size, i32* %size
    ret void
}

define i1 @tokenMatches(%Token* %token, i8* %str) {
    %data = getelementptr %Token, %Token* %token, i32 0, i32 0
    %size = getelementptr %Token, %Token* %token, i32 0, i32 1
    %current_size = load i32, i32* %size
    %i = alloca i32
    store i32 0, i32* %i
    br label %loop

  loop:
    %j = load i32, i32* %i
    %cmp = icmp slt i32 %j, %current_size
    br i1 %cmp, label %check, label %done

  check:
    %data_ptr = getelementptr i8, i8* %data, i32 %j
    %data_char = load i8, i8* %data_ptr
    %str_ptr = getelementptr i8, i8* %str, i32 %j
    %str_char = load i8, i8* %str_ptr
    %cmp = icmp eq i8 %data_char, %str_char
    br i1 %cmp, label %inc, label %fail

  inc:
    %new_i = add i32 %j, 1
    store i32 %new_i, i32* %i
    br label %loop

  fail:
    ret i1 false

  done:
    %cmp = icmp eq i32 %j, %current_size
    ret i1 %cmp
}

define i1 @tokenEq(%Token* %token1, %Token* %token2) {
    %data1 = getelementptr %Token, %Token* %token1, i32 0, i32 0
    %size1 = getelementptr %Token, %Token* %token1, i32 0, i32 1
    %data2 = getelementptr %Token, %Token* %token2, i32 0, i32 0
    %size2 = getelementptr %Token, %Token* %token2, i32 0, i32 1
    %size1_val = load i32, i32* %size1
    %size2_val = load i32, i32* %size2
    %cmp = icmp eq i32 %size1_val, %size2_val
    br i1 %cmp, label %loop, label %fail

  loop:
    %i = phi i32 [ 0, %entry ], [ %new_i, %inc ]
    %data1_ptr = getelementptr i8, i8* %data1, i32 %i
    %data2_ptr = getelementptr i8, i8* %data2, i32 %i
    %data1_char = load i8, i8* %data1_ptr
    %data2_char = load i8, i8* %data2_ptr
    %cmp = icmp eq i8 %data1_char, %data2_char
    br i1 %cmp, label %inc, label %fail

  inc:
    %new_i = add i32 %i, 1
    %cmp = icmp slt i32 %new_i, %size1_val
    br i1 %cmp, label %loop, label %done

  fail:
    ret i1 false

  done:
    ret i1 true
}

define i8* @tokenToString(%Token* %token) {
    %data = getelementptr %Token, %Token* %token, i32 0, i32 0
    %size = getelementptr %Token, %Token* %token, i32 0, i32 1
    %current_size = load i32, i32* %size
    %str = call i8* @malloc(i64 %current_size)
    %0 = bitcast i8* %str to i8*
    %1 = getelementptr i8, i8* %data, i32 0
    %2 = bitcast i8* %0 to i8**
    store i8* %0, i8** %2
    %3 = bitcast i8* %1 to i8*
    %4 = getelementptr i8, i8* %0, i32 0
    store i8* %3, i8** %4
    ret i8* %str
}

define %Token* @reverseToken(%Token* %token) {
    %data = getelementptr %Token, %Token* %token, i32 0, i32 0
    %size = getelementptr %Token, %Token* %token, i32 0, i32 1
    %current_size = load i32, i32* %size
    %new_token = call %Token @newObject(i32 %current_size)
    %i = alloca i32
    store i32 0, i32* %i
    br label %loop

  loop:
    %j = load i32, i32* %i
    %cmp = icmp slt i32 %j, %current_size
    br i1 %cmp, label %copy, label %done

  copy:
    %data_ptr = getelementptr i8, i8* %data, i32 %j
    %data_char = load i8, i8* %data_ptr
    %new_data = getelementptr %Token, %Token* %new_token, i32 0, i32 0
    %new_data_ptr = getelementptr i8, i8* %new_data, i32 %j
    store i8 %data_char, i8* %new_data_ptr
    %new_size = getelementptr %Token, %Token* %new_token, i32 0, i32 1
    store i32 %current_size, i32* %new_size
    %new_i = add i32 %j, 1
    store i32 %new_i, i32* %i
    br label %loop

  done:
    ret %Token* %new_token
}

define %Token* @concatTokens(%Token* %token1, %Token* %token2) {
    %data1 = getelementptr %Token, %Token* %token1, i32 0, i32 0
    %size1 = getelementptr %Token, %Token* %token1, i32 0, i32 1
    %data2 = getelementptr %Token, %Token* %token2, i32 0, i32 0
    %size2 = getelementptr %Token, %Token* %token2, i32 0, i32 1
    %size1_val = load i32, i32* %size1
    %size2_val = load i32, i32* %size2
    %new_size = add i32 %size1_val, %size2_val
    %new_token = call %Token @newObject(i32 %new_size)
    %i = alloca i32
    store i32 0, i32* %i
    br label %loop1

  loop1:
    %j = load i32, i32* %i
    %cmp = icmp slt i32 %j, %size1_val
    br i1 %cmp, label %copy1, label %loop2

  copy1:
    %data1_ptr = getelementptr i8, i8* %data1, i32 %j
    %data1_char = load i8, i8* %data1_ptr
    %new_data = getelementptr %Token, %Token* %new_token, i32 0, i32 0
    %new_data_ptr = getelementptr i8, i8* %new_data, i32 %j
    store i8 %data1_char, i8* %new_data_ptr
    %new_size = getelementptr %Token, %Token* %new_token, i32 0, i32 1
    store i32 %new_size, i32* %new_size
    %new_i = add i32 %j, 1
    store i32 %new_i, i32* %i
    br label %loop1

  loop2:
    %j = load i32, i32* %i
    %cmp = icmp slt i32 %j, %new_size
    br i1 %cmp, label %copy2, label %done

  copy2:
    %data2_ptr = getelementptr i8, i8* %data2, i32 %j
    %data2_char = load i8, i8* %data2_ptr
    %new_data = getelementptr %Token, %Token* %new_token, i32 0, i32 0
    %new_data_ptr = getelementptr i8, i8* %new_data, i32 %j
    store i8 %data2_char, i8* %new_data_ptr
    %new_size = getelementptr %Token, %Token* %new_token, i32 0, i32 1
    store i32 %new_size, i32* %new_size
    %new_i = add i32 %j, 1
    store i32 %new_i, i32* %i
    br label %loop2

  done:
    ret %Token* %new_token
}
