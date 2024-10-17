declare
  v_id_reg           epc_apuracao.id_reg%type;
  v_id_reg_cred_disp epc_apur_cred_disp.id_reg_cred_disp%type;
  v_existe           varchar2(1);
  v_rowid            varchar2(1000);
begin

  for i in (select d.rowid rowid_w,
                   d.cod_empresa,
                   d.per_apu_cred,
                   d.cod_pis_cofins,
                   d.cod_cred,
                   d.vlr_cred_apur,
                   nvl(d.vlr_cred_util_desc_anterior,0) vlr_cred_util_desc,
                   d.vlr_cred_disp,
                   to_date(lpad(per_apu_cred,6,0), 'MMRRRR') dt_apur_ini,
                   last_day(to_date(lpad(per_apu_cred,6,0), 'MMRRRR')) dt_apur_fim
              from wmx_tratacred_piscof d
             where feito is null) loop
  
    begin
      select id_reg
        into v_id_reg
        from epc_apuracao s
       where cod_empresa = i.cod_empresa
         and s.dat_apur_ini >= i.dt_apur_ini
         and s.dat_apur_fim <= i.dt_apur_fim;
    
    exception
      when others then
        v_id_reg := null;
    end;
  
    begin
      select nvl(max(id_reg_cred_disp), 0) + 1
        into v_id_reg_cred_disp
        from epc_apur_cred_disp;
    
    exception
      when others then
        v_id_reg_cred_disp := null;
    end;
  
    begin
      select 'S', rowid
        into v_existe, v_rowid
        from epc_apur_cred_disp k
       where k.id_reg = v_id_reg
         and k.cod_pis_cofins = i.cod_pis_cofins
         and k.cod_cred = i.cod_cred
         and k.per_apu_cred = i.per_apu_cred;
    
    exception
      when others then
        v_existe := 'N';
    end;
  
    if v_existe = 'S' then
    
      update epc_apur_cred_disp ss
         set ss.vlr_cred_apur      = i.vlr_cred_apur,
             ss.vlr_cred_util_desc = i.vlr_cred_util_desc,
             ss.vlr_cred_disp      = i.vlr_cred_disp
       where ss.rowid = v_rowid;
      commit;
    
      begin
        update wmx_tratacred_piscof d
           set feito = 'S'
         where rowid = i.rowid_w;
      
        commit;
      exception
        when others then
          null;
      end;
      v_existe := 'N';
    elsif (v_id_reg_cred_disp is not null) and (v_id_reg is not null) and
          (v_existe = 'N') then
    
      insert into epc_apur_cred_disp
        (id_reg_cred_disp,
         id_reg,
         cod_pis_cofins,
         cod_cred,
         ind_cred_ori,
         cnpj_suc,
         vlr_cred_apur,
         vlr_cred_apur_extemp,
         vlr_cred_util_desc,
         vlr_cred_util_per,
         vlr_cred_util_dcomp,
         vlr_cred_util_trans,
         vlr_cred_util_out,
         vlr_cred_disp,
         ind_gravacao,
         per_apu_cred)
      values
        (v_id_reg_cred_disp, --ID lançameto de crédito
         v_id_reg, --ID da apuração
         i.cod_pis_cofins,
         i.cod_cred,
         '0',
         '00000000000000',
         i.vlr_cred_apur, --vlr_cred_apur
         0.00,
         i.vlr_cred_util_desc, --vlr_cred_util_desc
         0.00,
         0.00,
         0.00,
         0.00,
         i.vlr_cred_disp, --vlr_cred_disp
         6,
         i.per_apu_cred);
    
      update wmx_tratacred_piscof d
         set feito = 'S'
       where rowid = i.rowid_w;
    
      commit;
    end if;
  
    dbms_output.put_line('Periodo ' || i.per_apu_cred || ' ' ||
                         v_id_reg_cred_disp || ' ' || v_id_reg || ' ' ||
                         i.cod_pis_cofins || ' ' || i.cod_cred || ' ' ||
                         i.vlr_cred_apur || ' ' || i.vlr_cred_util_desc || ' ' ||
                         i.vlr_cred_disp);
  end loop;
exception
  when others then
    dbms_output.put_line(sqlerrm);
end;
