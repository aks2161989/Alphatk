-- SQL-Example.sql
--
-- source of original document:
--
-- <http://gserver.grads.vt.edu/>

-- PL/SQL utility package to access regex.
-- created 13 sept 95 by tdunbar@gserver.grads.vt.edu

create or replace package regex as
  function amatch(regex_i in varchar2, string_i in varchar2,
                    timeout in number default 10) return number;
  procedure match(regex_i in varchar2, string_i in varchar2);
  procedure stop(timeout number default 10);

end regex;
/

create or replace package body regex as

  procedure match(regex_i in varchar2, string_i in varchar2) is
      i number;
    begin
      i:=amatch(regex_i,string_i);
      htp.p('returns '||i);
    end;

  function amatch(regex_i in varchar2, string_i in varchar2,  
                     timeout in number default 10) return number is
    s number;
    result varchar2(20);
    command_code number;
    pipe_name varchar2(30);
  begin
    pipe_name := dbms_pipe.unique_session_name;
    dbms_pipe.pack_message('AMATCH');
    dbms_pipe.pack_message(pipe_name);
    dbms_pipe.pack_message(regex_i);
    dbms_pipe.pack_message(string_i);
    s := dbms_pipe.send_message('amatch', timeout);
    if s <> 0 then
      raise_application_error(-20010,
        'Execute_system: Error while sending.  Status = ' || s);
    end if;

    s := dbms_pipe.receive_message(pipe_name, timeout);
    if s <> 0 then
      raise_application_error(-20011,
        'Execute_system: Error while receiving.  Status = ' || s);
    end if;

    dbms_pipe.unpack_message(result);
    if result <> 'done' then
      raise_application_error(-20012,
        'Execute_system: Done not received.');
    end if;

    dbms_pipe.unpack_message(command_code);
    return command_code;
  end amatch;

  procedure stop(timeout number default 10) is
    s number;
  begin

    dbms_pipe.pack_message('STOP');
    s := dbms_pipe.send_message('amatch', timeout);
    if s <> 0 then
      raise_application_error(-20030,
        'Stop: Error while sending.  Status = ' || s);
    end if;
  end stop;

end regex;
/
show errors;
