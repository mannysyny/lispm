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
%object = type opaque

; Define a new type for the garbage collector's heap
%block = type { %block*, i32, [0 x %object] }

; Define a global variable to hold the head of the heap
@heap = global %block* null

; Define a function to allocate a new memory block and add it to the heap
define %block* @alloc_block(i32 %size) {
    %block_size = add i32 %size, 4
    %block_size = and i32 %block_size, -4
    %block_size = add i32 %block_size, 4
    %block_ptr = call i8* @malloc(i32 %block_size)
    %block = bitcast i8* %block_ptr to %block*
    %block.size = %size
    %block.next = @heap
    store %block* %block, %block** @heap
    ret %block* %block
}

; Define a function to mark all reachable objects in the heap
define void @mark() {
    ; Initialize the stack with roots
    %stack = alloca [100 x %object*]
    %stack_top = getelementptr [100 x %object*], [100 x %object*]* %stack, i32 0, i32 0
    %stack_ptr = getelementptr [100 x %object*], [100 x %object*]* %stack, i32 0, i32 0
    %stack_end = getelementptr [100 x %object*], [100 x %object*]* %stack, i32 0, i32 100

    ; Push roots onto stack
    %null = bitcast i32 0 to %object*
    %heap = load %block*, %block** @heap
    %stack_ptr_next = getelementptr %object*, %object** %stack_ptr, i32 1
    store %object* %null, %object** %stack_ptr
    %stack_ptr = %stack_ptr_next
    %stack_ptr_next = getelementptr %object*, %object** %stack_ptr, i32 1
    store %object* %heap, %object** %stack_ptr
    %stack_ptr = %stack_ptr_next

    ; Mark phase
    while icmp ult %stack_ptr, %stack_end {
        %stack_ptr_val = load %object*, %object** %stack_ptr
        %stack_ptr_next = getelementptr %object*, %object** %stack_ptr, i32 1
        %stack_ptr = %stack_ptr_next

        ; Check if object has already been marked
        %is_marked = icmp ne i32 0, and i32 1, %stack_ptr_val
        br i1 %is_marked, label %continue, label %mark_object

        mark_object:
        ; Mark object
        %stack_ptr_val_marked = or i32 1, %stack_ptr_val
        store %object* %stack_ptr_val_marked, %object** %stack_ptr_next

        ; Iterate over object's fields and push them onto stack
        %object_fields = getelementptr %object, %object* %stack_ptr_val, i32 0, i32 0
        %object_size = getelementptr %object, %object* %stack_ptr_val, i32 0, i32 1
        %object_size_val = load i32, i32* %object_size
        %object_fields_end = getelementptr [0 x %object], [0 x %object]* %object_fields, i32 0, i32 %object_size_val
        br label %push_fields

        push_fields:
        %object_fields_ptr = phi %object** [%object_fields, %mark_object], [%object_fields_next, %push_fields]
        %object_fields_ptr_next = getelementptr %object*, %object** %object_fields_ptr, i32 1
        %object_fields_next = getelementptr %object*, %object** %object_fields_ptr, i32 1
        %object_fields_val = load %object*, %object** %object_fields_ptr
        %is_null = icmp eq %object* null, %object_fields_val
        br i1 %is_null, label %continue, label %push_field

        push_field:
        %stack_ptr_next = getelementptr %object*, %object** %stack_ptr, i32 1
        store %object* %object_fields_val, %object** %stack_ptr
        %stack_ptr = %stack_ptr_next
        br label %push_fields

        continue:
    }
}
}

; Define a function to sweep all unreachable objects from the heap
define void @sweep() {
    ; Initialize current and previous pointers
    %current = load %block*, %block** @heap
    %prev = null

    ; Iterate over all blocks in the heap
    while %current != null {
        ; Initialize current and previous object pointers
        %current_obj = getelementptr %block, %block* %current, i32 1
        %prev_obj = null

        ; Iterate over all objects in the block
        while %current_obj < %current.end {
            ; Check if object has been marked
            %is_marked = and i32 1, load i32, i32* %current_obj
            %current_obj_size = getelementptr %object, %object* %current_obj, i32 0, i32 1

            ; If object has not been marked, free it
            br i1 %is_marked, label %continue, label %free_object

            free_object:
            ; Free object
            %next_obj = getelementptr %object, %object* %current_obj, i32 1
            %prev_obj_next = getelementptr %object*, %object** %prev_obj, i32 1
            store %object* %next_obj, %object** %prev_obj_next
            %current_obj_size_val = load i32, i32* %current_obj_size
            %current_obj_size_aligned = and i32 %current_obj_size_val, -4
            %current_obj_size_aligned_plus_4 = add i32 %current_obj_size_aligned, 4
            %current_obj_ptr = bitcast %object* %current_obj to i8*
            call void @free(i8* %current_obj_ptr)
            %current_obj = %next_obj
            br label %continue

            continue:
            ; Update previous object pointer
            %prev_obj = %current_obj
            %current_obj_next = getelementptr %object, %object* %current_obj, i32 1
            %current_obj = %current_obj_next
        }

        ; If block is empty, remove it from the heap
        %current_obj_size = getelementptr %block, %block* %current, i32 0, i32 0
        %current_obj_size_val = load i32, i32* %current_obj_size
        %current_obj_size_aligned = and i32 %current_obj_size_val, -4
        %current_obj_size_aligned_plus_4 = add i32 %current_obj_size_aligned, 4
        %current_size = mul i32 %current_obj_size_aligned_plus_4, 4
        %is_empty = icmp eq i32 %current_size, 0
        br i1 %is_empty, label %free_block, label %continue_block

        free_block:
        ; Free block
        %next = getelementptr %block, %block* %current, i32 1
        %prev_next = getelementptr %block**, %block*** %prev, i32 1
        store %block** %next, %block*** %prev_next
        %current_ptr = bitcast %block* %current to i8*
        call void @free(i8* %current_ptr)
        %current = %next
        br label %continue

        continue_block:
        ; Update previous block pointer
        %prev = %current
        %current_next = getelementptr %block, %block* %current, i32 2
        %current = %current_next
    }
}

define void @gc() {
    ; Mark phase
    call void @mark()

    ; Sweep phase
    call void @sweep()
}

define void @init() {
    ; Initialize heap
    %block = call %block* @alloc_block(i32 0)

    ; Call garbage collector periodically
    call void @atexit(void ()* @gc)
    call void @signal(i32 14, void (%object*)* @gc)
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