
configuration cnf_cmp_beh_algo of tb_cmp is
  for structure
    
    for mem_beh:memory use entity work.memory(test);
    end for;
    for proc_beh:MIPS_Processor use entity work.MIPS_Processor(behaviour);
    end for;

    for mem_cmp:memory use entity work.memory(test);
    end for;
    
    for proc_cmp:mips_processor use entity work.mips_processor(algorithm);
     end for;

  end for;
end cnf_cmp_beh_algo;