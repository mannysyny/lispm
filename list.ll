declare i8* @malloc(i32) nounwind

%object = type opaque

@val_nil = external global %object*

declare %object* @newObject(i32, i8*)
declare i32 @tag(%object*)
declare i8* @unbox(%object*)

%list = type {
      %object*,  ; Value (null on last element)
      %object*   ; Next node (null on last element)
}

define i1 @isNil(%object* %obj) {
    %tag = call i32 @tag(%object* %obj)

    %is_list = icmp eq i32 %tag, 0
    br i1 %is_list, label %check_nil, label %not_nil

not_nil:
    ret i1 false

check_nil:
    %val = call i8* @unbox(%object* %obj)

    %cellPtr = bitcast i8* %val to %list*
    %headPtr = getelementptr %list, %list* %cellPtr, i32 0, i32 0
    %head = load %object*, %object** %headPtr
    %is_nil = icmp eq %object* %head, null

    ret i1 %is_nil
}

; returns:
; Object: tag list
;         value -> List: value -> head (Object or nil)
;                        next -> tail (Object of type list)
;
; Cons null with null to create an empty list/nil.
; Cons Obj with nil to create a list of 1 element.
define %object* @cons(%object* %head, %object* %tail) {
    %is_null = icmp eq %object* null, %tail
    br i1 %is_null, label %cons_list, label %check_list

check_list:
    %tailTag = call i32 @tag(%object* %tail)
    %is_list = icmp eq i32 0, %tailTag
    br i1 %is_list, label %cons_list, label %cons_nil

cons_list:
    %listSize = getelementptr %list, %list* null, i32 1
    %listSizeI = ptrtoint %list* %listSize to i32

    %listSpace = call i8* @malloc(i32 %listSizeI)
    %listPtr = bitcast i8* %listSpace to %list*

    %valPtr = getelementptr %list, %list* %listPtr, i32 0, i32 0
    store %object* %head, %object** %valPtr

    %nextPtr = getelementptr %list, %list* %listPtr, i32 0, i32 1
    store %object* %tail, %object** %nextPtr

    %objectPtr = call %object* @newObject(i32 0, i8* %listSpace)
    ret %object* %objectPtr

cons_nil:
    %nil = load %object*, %object** @val_nil
    %tailList = call %object* @cons(%object* %tail, %object* %nil)
    %fullList = call %object* @cons(%object* %head, %object* %tailList)
    ret %object* %fullList
}

define %object* @first(%object* %obj) {
    %is_nil = call i1 @isNil(%object* %obj)
    br i1 %is_nil, label %ret_nil, label %ret_head

ret_nil:
    ret %object* %obj

ret_head:
    %val = call i8* @unbox(%object* %obj)

    %cellPtr = bitcast i8* %val to %list*

    %headPtr = getelementptr %list, %list* %cellPtr, i32 0, i32 0
    %head = load %object*, %object** %headPtr

    ret %object* %head
}

define %object* @rest(%object* %obj) {
    %is_nil = call i1 @isNil(%object* %obj)
    br i1 %is_nil, label %ret_nil, label %ret_rest

ret_nil:
    ret %object* %obj

ret_rest:
    %val = call i8* @unbox(%object* %obj)

    %cellPtr = bitcast i8* %val to %list*

    %tailPtr = getelementptr %list, %list* %cellPtr, i32 0, i32 1
    %tail = load %object*, %object** %tailPtr

    ret %object* %tail
}

; returns:
; Object: tag list
;         value -> List: value -> head (Object or nil)
;                        next -> tail (Object of type list)
;
; Appends two lists together.
define %object* @append(%object* %list1, %object* %list2) {
    %is_nil1 = call i1 @isNil(%object* %list1)
    %is_nil2 = call i1 @isNil(%object* %list2)

    br i1 %is_nil1, label %ret_list2, label %not_nil1

not_nil1:
    %head1 = call %object* @first(%object* %list1)
    %tail1 = call %object* @rest(%object* %list1)

    %newList = call %object* @cons(%object* %head1, %object* %list2)
    %appendedList = call %object* @append(%object* %tail1, %object* %list2)

    %is_nil = call i1 @isNil(%object* %appendedList)
    br i1 %is_nil, label %ret_new_list, label %not_nil

not_nil:
    %head = call %object* @first(%object* %appendedList)
    %tail = call %object* @rest(%object* %appendedList)

    %newList = call %object* @cons(%object* %head, %object* %newList)
    %appendedList = call %object* @append(%object* %tail1, %object* %tail)

    br label %ret_new_list

ret_new_list:
    ret %object* %newList

ret_list2:
    ret %object* %list2
}
