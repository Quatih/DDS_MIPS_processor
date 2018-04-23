
configuration cnf_dp_controller_post of tb_dpc is
  for structure
    for alu:alu_design use entity work.alu_design(behaviour);
    end for;
    for ctrl:controller use entity work.controller(behaviour);
    end for;
    --for dp:datapath use entity work.datapath(rtl);
    -- for dp:datapath use entity work.datapath(behaviour);
    
    for dp:datapath use entity work.datapath(structure);--postsynth
    end for;
    for mem:memory use entity work.memory(test);
    -- for mem:memory use entity work.memory(behaviour);
    end for;
  end for;
end cnf_dp_controller_post;