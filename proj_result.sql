

-- Q1:

CREATE OR REPLACE VIEW Q1(subject_code) AS
SELECT DISTINCT Subjects.code
FROM Subjects
JOIN Orgunits ON Orgunits.id = Subjects.uoc
JOIN Orgunit_types ON Orgunit_types.id = Orgunits.utype
WHERE Orgunit_types.name = 'School'
AND Orgunits.longname LIKE '%Information%'
AND Subjects.code LIKE '____7___'
AND Orgunits.utype = 2;



--#################################################

-- Q2:
create or replace view Q2(course_id)
as
SELECT co.id AS course_id
FROM courses co
INNER JOIN subjects sub ON co.subject = sub.id
INNER JOIN classes cl ON co.id = cl.course
INNER JOIN class_types cltp ON cl.ctype = cltp.id
WHERE sub.code LIKE 'COMP%'
AND cltp.name IN ('Lecture', 'Laboratory')
AND co.id NOT IN (
    SELECT co2.id
    FROM courses co2
    INNER JOIN subjects sub2 ON co2.subject = sub2.id
    INNER JOIN classes cl2 ON co2.id = cl2.course
    INNER JOIN class_types cltp2 ON cl2.ctype = cltp2.id
    WHERE sub2.code LIKE 'COMP%'
    AND cltp2.name NOT IN ('Lecture', 'Laboratory')
)
GROUP BY co.id
HAVING COUNT(DISTINCT cltp.id) = 2;
;

--##############################################

-- Q3:
create or replace view Q3(unsw_id)
as
select people.unswid from people 
join students on students.id = people.id
join course_enrolments on course_enrolments.student = students.id
join courses on courses.id = course_enrolments.course
join semesters on semesters.id = courses.semester
join (SELECT DISTINCT course_staff.course
FROM course_staff
JOIN courses ON courses.id = course_staff.course
JOIN staff ON staff.id = course_staff.staff 
JOIN people ON people.id = staff.id
WHERE people.title = 'Prof'
AND course_staff.course IN (
    SELECT course_staff.course
    FROM staff
    JOIN people ON people.id = staff.id
    JOIN course_staff ON staff.id = course_staff.staff
    WHERE people.title = 'Prof'
    GROUP BY course_staff.course
    HAVING COUNT(staff.id) >= 2
))as A on A.course = course_enrolments.course

where semesters.year between 2008 and 2012
and cast(people.unswid as varchar) like '320%'
group by people.unswid
having count(A.course)>=5;


-- Q4:
create or replace view Q4(course_id, avg_mark)
as
SELECT 
    Q4_1.course AS course_id,
    Q4_1.avg_mark
FROM 
    (
        SELECT 
            course_enrolments.course,
            ROUND(AVG(mark)::NUMERIC, 2) AS avg_mark
        FROM 
            course_enrolments
        WHERE 
            grade = 'DN' OR grade = 'HD'
        GROUP BY 
            course_enrolments.course
    ) AS Q4_1
JOIN 
    courses ON Q4_1.course = courses.id
JOIN 
    subjects ON courses.subject = subjects.id
JOIN 
    orgunits ON subjects.offeredby = orgunits.id
JOIN 
    orgunit_types ON orgunits.utype = orgunit_types.id
JOIN 
    (
        SELECT 
            orgunits.id AS orgunit,
            semesters.id AS semester,
            MAX(Q4_1.avg_mark) AS max_avg_mark
        FROM 
            (
                SELECT 
                    course_enrolments.course,
                    ROUND(AVG(mark)::NUMERIC, 2) AS avg_mark
                FROM 
                    course_enrolments
                WHERE 
                    grade = 'DN' OR grade = 'HD'
                GROUP BY 
                    course_enrolments.course
            ) AS Q4_1
        JOIN 
            courses ON Q4_1.course = courses.id
        JOIN 
            semesters ON courses.semester = semesters.id
        JOIN 
            subjects ON courses.subject = subjects.id
        JOIN 
            orgunits ON subjects.offeredby = orgunits.id
        JOIN 
            orgunit_types ON orgunits.utype = orgunit_types.id
        WHERE 
            orgunit_types.name = 'Faculty' AND semesters.year = 2012
        GROUP BY 
            orgunits.id, semesters.id
    ) AS Q4_2 ON Q4_1.course = courses.id
WHERE 
    Q4_2.orgunit = orgunits.id 
    AND Q4_2.semester = courses.semester 
    AND Q4_1.avg_mark = Q4_2.max_avg_mark;


-- Q5:
create view Q5_1 as
select course_enrolments.course, courses.semester
from course_enrolments 
join courses on course_enrolments.course = courses.id
join semesters on courses.semester = semesters.id
where semesters.year >= 2005 and semesters.year <= 2015
group by course_enrolments.course, courses.semester
having count(course_enrolments.student) > 500;

create view Q5_2 as
select course_staff.course, courses.semester
From course_staff join staff on course_staff.staff = staff.id
Join people on staff.id = people.id
join courses on course_staff.course = courses.id
join semesters on courses.semester = semesters.id
Where people.title = 'Prof' and semesters.year >= 2005 and semesters.year <= 2015
Group by course_staff.course, courses.semester
Having count(people.title) >= 2;

create view Q5_3 as
select Q5_1.course, people.given
from Q5_1 join Q5_2 on Q5_1.course = Q5_2.course
join course_staff on Q5_1.course = course_staff.course
join staff on course_staff.staff = staff.id
Join people on staff.id = people.id
Where people.title = 'Prof'
order by Q5_1.course, people.given;

create or replace view Q5(course_id, staff_name)
as
select course course_id, STRING_AGG(given, '; ') AS staff_name
from Q5_3
group by course;




-- Q6:

create view Q61 as
select rooms.id, count(classes.id)
from rooms join classes on classes.room = rooms.id
join courses on classes.course = courses.id
join semesters on courses.semester = semesters.id
where semesters.year = 2012
group by rooms.id;

create view Q62 as
select id
from Q61
where count = (
    select max(count)
    from Q61);

create view Q63 as
select Q62.id, subjects.code, count(subjects.code)
from Q62 join rooms on Q62.id = rooms.id
join classes on classes.room = rooms.id
join courses on classes.course = courses.id
join subjects on courses.subject = subjects.id
join semesters on courses.semester = semesters.id
where semesters.year = 2012
group by Q62.id, subjects.code;


create view Q64 as
select id, max(count)
from Q63
group by id;

create or replace view Q6(room_id, subject_code)
as select id room_id, code subject_code
from Q63 
where (id, count) in (
    select *
    from Q64
);



-- Q7:
create or replace view q71 as
select 
st.id as student_id,
pe.unswid,
og.id as orgunit_id,
p_e.program as program_id,
co.semester,
su.uoc as subject_uoc,
pro.uoc as program_uoc
from students st
join people pe on st.id = pe.id
join program_enrolments p_e on st.id = p_e.student
join programs pro on p_e.program = pro.id
join orgunits og on pro.offeredby = og.id
join course_enrolments c_e on st.id = c_e.student 
join courses co on c_e.course = co.id and co.semester = p_e.semester
join subjects su on co.subject = su.id
where c_e.mark >= 50;

create or replace view q72 as 
select
unswid,
orgunit_id,
program_id,
sum(subject_uoc) as total_uoc,
program_uoc
from q71
group by unswid,orgunit_id,program_id,program_uoc
having sum(subject_uoc) >= program_uoc;

create or replace view q73 as
select 
q72.unswid,
q72.orgunit_id
from q72
join people pe on q72.unswid = pe.unswid
join students st on st.id = pe.id
join program_enrolments p_e on p_e.program = q72.program_id
and p_e.student = st.id
join semesters se on se.id = p_e.semester
group by q72.unswid,q72.orgunit_id
having max(se.ending)- min(se.starting)<1000
and count(distinct q72.program_id)>=2;

create or replace view q7(student_id,program_id)
as
select q73.unswid,q72.program_id
from q72 join q73 on q72.unswid = q73.unswid
and q72.orgunit_id = q73.orgunit_id;



-- Q8:

create view Q8_1 as
select staff, orgunit, count(role)
from affiliations
group by staff, orgunit
having count(role) >= 3;

--//View Q8_2  role//

create or replace view Q8_2 as
select Q8_1.staff, count(distinct affiliations.*)
from Q8_1 join affiliations on Q8_1.staff = affiliations.staff
group by Q8_1.staff;

--//View Q8_3 course

create view Q8_3 as
select Q8_2.staff, course_staff.course
from Q8_2 join course_staff on Q8_2.staff = course_staff.staff
join staff_roles on course_staff.role = staff_roles.id
join courses on course_staff.course = courses.id
join semesters on courses.semester = semesters.id
where staff_roles.name = 'Course Convenor' and
semesters.year = 2012;

View Q8_4 

create view Q8_4 as
select Q8_3.staff, count(course_enrolments.student)
from Q8_3 join course_enrolments on Q8_3.course = course_enrolments.course
where course_enrolments.mark >= 75
group by Q8_3.staff;

View Q8_5

create view Q8_5 as
select Q8_3.staff, count(course_enrolments.student)
from Q8_3 join course_enrolments on Q8_3.course = course_enrolments.course
where course_enrolments.mark is not null
group by Q8_3.staff;

View Q8_6

CREATE OR REPLACE VIEW Q8_6 AS
WITH RankedResults AS (
    SELECT 
        people.unswid AS staff_id,
        Q8_2.count AS sum_roles,
        ROUND(Q8_4.count::numeric / Q8_5.count::numeric, 2) AS hdn_rate,
        RANK() OVER (ORDER BY ROUND(Q8_4.count::numeric / Q8_5.count::numeric, 2) DESC, Q8_2.count DESC) AS ranking
    FROM 
        Q8_4 
    JOIN 
        Q8_5 ON Q8_5.staff = Q8_4.staff
    JOIN 
        Q8_2 ON Q8_2.staff = Q8_5.staff
    JOIN 
        people ON Q8_5.staff = people.id
)
SELECT 
    staff_id, 
    sum_roles, 
    hdn_rate
FROM 
    RankedResults
WHERE 
    ranking <= 20
ORDER BY 
    hdn_rate DESC, sum_roles DESC;


create or replace view Q8(staff_id, sum_roles, hdn_rate) 
as 
select * from q8_6
;
--#########################################################################################################################

-- Q9

create view Q9_1 as
select courses.id course
from courses join subjects on courses.subject = subjects.id
where POSITION(LEFT(code, 4) IN _prereq) > 0
group by courses.id
having count(subjects._prereq) >= 1;


create view Q9_2 as
select 
course_enrolments.student, 
course_enrolments.course, 
course_enrolments.mark
from Q9_1 join course_enrolments on Q9_1.course = course_enrolments.course
where course_enrolments.mark is not null;

--//排序//
create view Q9_3 as
select
    student,
    course,
    rank() over (partition by course order by mark desc) as course_rank
from
    Q9_2
order by course;

create function
    Q9(unsw_id integer) returns setof text as $$
declare 
    course_result text;
    warning_message text := 'WARNING: Invalid Student Input [' || unsw_id || ']';
begin
    if not exists (select 1 from Q9_3 join people on Q9_3.student = people.id where people.unswid = unsw_id) then
        return next warning_message;
        return;
    end if;

    for course_result in
        select
            concat(subjects.code, ' ',Q9_3.course_rank) as result 
        from
            Q9_3 join people on Q9_3.student = people.id
            join courses on courses.id = Q9_3.course
            join subjects on courses.subject = subjects.id
        where
            people.unswid = unsw_id
    loop
        return next course_result;
    end loop;
end;
$$ language plpgsql;
--#########################################################################################################################

-- Q10

CREATE OR REPLACE VIEW q10_1 AS
SELECT 
    program_enrolments.student, 
    program_enrolments.program, 
    COALESCE(course_enrolments.course, 1) AS course
FROM 
    program_enrolments 
JOIN 
    students ON program_enrolments.student = students.id
JOIN 
    semesters ON program_enrolments.semester = semesters.id
LEFT JOIN 
    course_enrolments ON course_enrolments.student = students.id
LEFT JOIN 
    courses ON course_enrolments.course = courses.id
WHERE 
    program_enrolments.semester = courses.semester;

CREATE OR REPLACE VIEW q10_2 AS
SELECT 
    q10_1.*, 
    subjects.uoc,
    COALESCE(course_enrolments.mark, 1) AS mark
FROM 
    q10_1 
JOIN 
    course_enrolments ON (q10_1.student, q10_1.course) = (course_enrolments.student, course_enrolments.course)
JOIN 
    courses ON q10_1.course = courses.id
JOIN 
    subjects ON courses.subject = subjects.id;

-- 
CREATE OR REPLACE VIEW q10_3 AS
SELECT 
    student, 
    program, 
    CASE 
        WHEN COUNT(*) FILTER (WHERE mark = 1) = COUNT(*) THEN SUM(uoc)  
        ELSE SUM(CASE WHEN mark <> 1 THEN uoc ELSE 0 END)  
    END AS sum
FROM 
    q10_2 
GROUP BY 
    student, 
    program;

CREATE OR REPLACE VIEW q10_4 AS
SELECT 
    Q10_1.*,
    subjects.uoc, 
    CASE 
        WHEN course_enrolments.mark IS NOT NULL THEN course_enrolments.mark
        ELSE 1
    END AS mark
FROM 
    Q10_1 
JOIN 
    course_enrolments ON (Q10_1.student, Q10_1.course) = (course_enrolments.student, course_enrolments.course)
JOIN 
    courses ON Q10_1.course = courses.id
JOIN 
    subjects ON courses.subject = subjects.id
WHERE 
    course_enrolments.grade NOT IN ('SY', 'XE', 'T', 'PE') 
   ;


CREATE OR REPLACE VIEW q10_5 AS
SELECT 
    q1.student, 
    q1.program, 
    CASE 
        WHEN COUNT(*) FILTER (WHERE q1.all_marks_are_1) = COUNT(*) THEN SUM(q1.uoc * q1.mark)
        ELSE SUM(CASE WHEN q1.mark <> 1 THEN q1.uoc * q1.mark ELSE 0 END)
    END AS sum
FROM 
    (
        SELECT 
            Q10_4.student, 
            Q10_4.program, 
            Q10_4.uoc, 
            Q10_4.mark,
            CASE 
                WHEN EXISTS (
                    SELECT 1
                    FROM Q10_4 AS q
                    WHERE q.program = Q10_4.program
                    AND q.mark <> 1
                ) THEN FALSE
                ELSE TRUE
            END AS all_marks_are_1
        FROM 
            Q10_4 
    ) AS q1
GROUP BY 
    q1.student, 
    q1.program;



create or replace view q10_6 as 
select 
people.unswid,programs.name,q10_3.program,
round((q10_5.sum)/(q10_3.sum)::numeric,2) wam
from q10_3 join q10_5 on q10_5.student = q10_3.student
join people on people.id =q10_3.student and people.id = q10_5.student
join programs on programs.id = q10_3.program and programs.id = q10_5.program

where q10_3.sum > 0
group by programs.id;

CREATE OR REPLACE FUNCTION q10(
    student_unswid INTEGER
)
RETURNS TABLE (
    result_text TEXT
) AS $$
BEGIN
    IF EXISTS (SELECT 1 FROM people WHERE unswid = student_unswid) THEN
        RETURN QUERY
        SELECT 
            CASE 
                WHEN q10_5.sum / q10_3.sum < 19 THEN CONCAT(people.unswid, ' ', programs.name, ' No WAM Available')
                ELSE CONCAT(people.unswid, ' ', programs.name, ' ', ROUND((q10_5.sum) / (q10_3.sum)::NUMERIC, 2)::TEXT)
            END AS result_text
        FROM 
            q10_3 
        JOIN 
            q10_5 ON q10_5.student = q10_3.student
        JOIN 
            people ON people.id = q10_3.student AND people.unswid = student_unswid
        JOIN 
            programs ON programs.id = q10_3.program AND programs.id = q10_5.program
        WHERE 
            people.unswid = student_unswid AND q10_3.sum > 0;
    ELSE
        RETURN QUERY
        SELECT CONCAT('WARNING: Invalid Student Input [', student_unswid, ']') AS result_text;
    END IF;
END;
$$ LANGUAGE plpgsql;
--######################################################################################################################################















































































