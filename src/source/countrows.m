function rows = countrows(pointCloudFilePath)
    if (isunix) % Linuxϵͳ�ṩ��wc�������ֱ��ʹ��
        % ʹ��syetem��������ִ�в���ϵͳ�ĺ���
        % ����window��dir��linux��ls��
        [~, numstr] = system( ['wc -l ', pointCloudFilePath] );
        rows=str2double(numstr);
    elseif (ispc) % Windowsϵͳ����ʹ��perl����
        if exist('countlines.pl','file')~=2
            % perl�ļ����ݺܼ򵥾�����
            % while (<>) {};
            % print $.,"\n";
            fid=fopen('countlines.pl','w');
            fprintf(fid,'%s\n%s','while (<>) {};','print $.,"\n";');
            fclose(fid);
        end
        % ִ��perl�ű�
        rows=str2double( perl('countlines.pl',pointCloudFilePath) );
    end
end