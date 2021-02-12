.data

values: .word 4, 2, 1, 3, 6, 5, 7, -9999
min: .word -9999 #to end the list
emptyString: .asciiz " "
tree: .space 4

#Each node of tree stored in 16-byte address
#Byte Address->Contents
#   A->Value of the node
# A+4->Address of the left child
# A+8->Address of the right child
# A+12->Address of the parent

.text
.globl main
main:
  la $a0, values
  jal build
  lw $t0, 0($s0)
  move $a0, $t0
  li $v0, 1
  syscall
  j exit

exit:
  li $v0, 10
  syscall

build:
  move $t1, $a0 #start of list

  #create first node
  li $a0, 16
  li $v0, 9
  syscall

  move $s0, $v0 #root node always at $s0
  lw $t4, 0($t1) #load first element
  sw $t4, 0($s0) #store value of first node
  sw $zero, 4($s0) #initialize 0
  sw $zero, 8($s0) #initialize 0
  sw $zero, 12($s0) #initialize 0

build_rest:
  addi $t1, $t1, 4 #increment lists address
  lw $t4, 0($t1) #load element
  lw $t8, min
  beq $t8, $t4, exit_build
  move $a0, $t4 #parameter for insert
  move $a1, $s0 #parameter for insert
  move $s3, $ra #saving return address
  jal insert
  move $ra, $s3
  j build_rest
exit_build:
  jr $ra

#insert(value, tree)
# a1 = root node when called in main
insert:
  move $t4, $a0 #value
  move $t2, $a1 # current node
  lw $t3, 0($t2) # get value of current node

  #compare value to be added and current nodes value
  slt $t9, $t3, $t4
  beq $t9, $zero, check_left
  lw $t8, 8($t2)
  beq $t8, $zero, else2
  move $a1, $t8
  move $a0, $t4
  j insert

else2:
  li $a0, 16
  li $v0, 9
  syscall
  move $t5, $v0 #create node and hold its address in $t5

  sw $t4, 0($t5)
  sw $zero, 4($t5)
  sw $zero, 8($t5) #store values at node
  sw $t5, 8($t2)
  sw $t2, 12($t5)
  sw $v0, 8($t2) #The address of the location where the new node was inserted
  j exit_insert
check_left:
  lw $t8, 4($t2)
  beq $t8, $zero, else3
  move $a1, $t8
  move $a0, $t4
  j insert
else3:
  li $a0, 16
  li $v0, 9
  syscall
  move $t5, $v0 #create node and hold its address in $t5

  sw $t4, 0($t5)
  sw $zero, 4($t5)
  sw $zero, 8($t5) #store values at node
  sw $t5, 4($t2)
  sw $t2, 12($t5)
  sw $v0, 4($t2) #The address of the location where the new node was inserted
exit_insert:
  jr $ra

#find(value, tree)
# a1 = root node when called in main
# if value found v0 = 0 and v1 = contains values address
# if value not found v0 = 1
find:
  move $t1, $a0 #value to be found
  move $t2, $a1 #address of node

  lw $t3, 0($t2) #value of node

  beq $t1, $t3, exit_find
  slt $t9, $t1, $t3
#if value to be found greater than node's value look for value in right sub tree
  beq $t9, $zero find_right
  lw $t4, 4($t2)
  beq $zero, $t4 exit_failure #if no address than the value isn't in tree
  j find_left
find_right:
  lw $t4, 8($t2)
  beq $zero, $t4 exit_failure #if no address than the value isn't in tree
  move $a0, $t1
  move $a1, $t4
  j find #search in right sub tree
find_left:
  move $a0, $t1
  move $a1, $t4
  j find #search in left sub tree
exit_failure:
  move $v0, $zero
  addi $v0, 1 #value doens't exist in tree
  jr $ra
exit_find:#value exists in the tree
  move $t4, $t2
  move $v1, $t4
  move $v0, $zero
  jr $ra

print:
  addi $sp, $sp, -8  #open space at stack
  sw $ra, 0($sp) #store return address

  move $t1, $a0 #load node

  lw $t8, 8($t1)
  sw $t8, 4($sp) #store address at right node

  lw $t9, 0($t1)
  move $a0, $t9
  beq $a0, $zero, print_exit

  li $v0, 1 #print value
  syscall

  li $v0, 4
  la $a0, emptyString #print emptyString
  syscall

  lw $t2, 4($t1)
  beq $t2, $zero print_right #if zero than no sub tree so exit
  move $a0, $t2
  jal print  #call print for left sub tree

print_right:
  lw $t5, 4($sp)
  beq $t5, $zero, print_exit #if zero than no sub tree so exit
  move $a0, $t5
  jal print #call print for right sub tree

print_exit:
  lw $ra, 0($sp)
  addi $sp, $sp, 8
  jr $ra
