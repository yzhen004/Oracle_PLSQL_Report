create or replace 
procedure REPORT_UG as
    cursor empCursor 
    is
    SELECT empinfo.fname, empinfo.lname, empinfo.ssn, empinfo.dname,
    NVL(super.sup_name, 'NONE') sup_name, empinfo.salary, NVL(dep.n_deps, 0) n_deps, NVL(CP.d_proj_num, 0) d_proj_num,
	NVL(CP.d_proj_hrs, 0) d_proj_hrs,
    NVL((CP.d_proj_cost * empinfo.salary/2000), 0) d_proj_cost, NVL(NCP.nd_proj_num, 0) nd_proj_num, 
	NVL(NCP.nd_proj_hrs, 0) nd_proj_hrs,
    NVL((NCP.nd_proj_cost * empinfo.salary/2000), 0) nd_proj_cost
    FROM
    (
      --Get the employee's first and last name, employee ssn, department name, salary
      SELECT E.fname, E.lname, E.ssn, D.dname, E.salary
      FROM DEPARTMENT D, EMPLOYEE E
      WHERE D.dnumber = E.dno
    )empinfo
    left outer join
    (
      --Get the supervisor's full name by self-joining employee table
      SELECT emp.ssn,
      NVL((sup.fname || ' ' || sup.minit || ' ' || sup.lname), 'NONE') sup_name
      FROM  EMPLOYEE emp, EMPLOYEE sup
      WHERE emp.superssn = sup.ssn
    )super ON empinfo.ssn = super.ssn
    left outer join
    (
      --Get the number of dependents the employee has
      SELECT essn, count(essn) n_deps
      FROM DEPENDENT
      GROUP BY essn
    )dep ON empinfo.ssn = dep.essn
    left outer join
    (
      --Get the total number of projects to which the employee is assigned
      --to controlled by his own department
      --and the number of hours the employee spent working on the projects
      SELECT A.essn, NVL(count(distinct A.pno), 0) d_proj_num, NVL(sum(A.hours), 0) d_proj_hrs,
      sum(A.hours) d_proj_cost
      FROM
      (
        SELECT w.essn, w.pno, w.hours, e.salary
        FROM WORKS_ON W, PROJECT P, EMPLOYEE E
        WHERE W.essn = E.ssn
        AND P.dnum = E.dno
        AND P.pnumber = w.pno
      )A
    GROUP BY A.essn
    )CP ON empinfo.ssn = CP.essn
    left outer join
    (
      --Get the total number of projects to which the employee is assigned to
      --NOT controlled by his own department
      --and the number of hours the employee spent working on the projects
      SELECT A.essn, NVL(count(distinct A.pno), 0) nd_proj_num, NVL(sum(A.hours), 0) nd_proj_hrs,
      sum(A.hours) nd_proj_cost
      FROM
      (
        SELECT w.essn, w.pno, w.hours, e.salary
        FROM WORKS_ON W, PROJECT P, EMPLOYEE E
        WHERE W.essn = E.ssn
        AND P.dnum <> E.dno
        AND P.pnumber = w.pno
      )A
      GROUP BY A.essn
    )NCP ON empinfo.ssn = NCP.essn;
     
    --Row variable of the cursor
    r empCursor%ROWTYPE; --used for fetch with empCursor
    
    --Row number, row count
    v_insert_number number;
    
begin --the start of the procedure
 
  --call clean procedure
 
  /*
    Cleaning the table: Since the user-name and insert-number form a key to the table,
    you will need to clean out what you have inserted between runs of your program 
    or you will get a primary key violation error. 
    You can clean out your entries from the table by using the procedure call
    ibl.clean_emp_summary('STUDEN_A'); where STUDEN_A represents your Oracle Login.
  */
  
  ibl.clean_emp_summary('yzheng');
 
  --Open the cursor
  open empCursor;
  --Fetch the first row
  fetch empCursor into r;
  
  --Set row number to 1
  v_insert_number :=1;
   
    --Call Insert procedure
    --Insert the first row
    ibl.ins_emp_summary(
         r.fname,  
         r.lname,  
         r.ssn,
         r.dname,
         r.sup_name,
         r.salary,
         r.n_deps,
         r.d_proj_num,
         r.d_proj_hrs,
         r.d_proj_cost,
         r.nd_proj_num,
         r.nd_proj_hrs,
         r.nd_proj_cost,
         'yzheng',
         v_insert_number);
   
    --Loop through the cursor
    while empCursor%FOUND loop
   
    fetch empCursor into r;
    
    --Update row number, increase row number by 1
    v_insert_number  := v_insert_number   +1;
    
    --Call Insert procedure 
    --Insert the next row
    ibl.ins_emp_summary(
         r.fname,  
         r.lname,  
         r.ssn,
         r.dname,
         r.sup_name,
         r.salary,
         r.n_deps,
         r.d_proj_num,
         r.d_proj_hrs,
         r.d_proj_cost,
         r.nd_proj_num,
         r.nd_proj_hrs,
         r.nd_proj_cost,
         'yzheng',
         v_insert_number);      
  
  end loop;
  close empCursor;
 
end; 
/