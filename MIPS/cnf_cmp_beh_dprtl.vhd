
configuration cnf_cmp_behaviour of tb_cmp is
  for structure
    
    for mem_beh:memory use entity work.memory(test);
    end for;
    for proc_beh:MIPS_Processor use entity work.MIPS_Processor(behaviour);
    end for;

    for mem_cmp:memory use entity work.memory(test);
    end for;
    
    for proc_cmp:mips_processor use entity work.mips_processor(mips_dp_ctrl);
      for mips_dp_ctrl
        for ctrl:controller use entity work.controller(behaviour);
        end for;
        for dp:datapath use entity work.datapath(rtl);
        end for;
        for alu:alu_design use entity work.alu_design(behaviour);
        end for;
      end for;
    end for;

  end for;
end cnf_cmp_behaviour;