program RESTClient;

{$APPTYPE CONSOLE}

uses
  SysUtils,
  SvWeb.Consts,
  GeoNamesClient in 'GeoNamesClient.pas',
  SvHTTPClient.Indy {/registers Indy Http client},
  SvVMI in '..\..\Core\SvVMI.pas',
  USAJobsClient in 'USAJobsClient.pas';

//use with Delphi XE2 or higher for best compatibility

procedure PrintJobs();
var
  LJobsClient: TUSAJobsClient;
  LJobs: TJobs;
  LJob: TJobData;
begin
  LJobsClient := TUSAJobsClient.Create('https://data.usajobs.gov/api');
  try
    LJobsClient.SetHttpClient(HTTP_CLIENT_INDY);
    LJobs := LJobsClient.GetITJobs();
    try
      Writeln(Format('Total IT jobs: %D', [LJobs.TotalJobs]) );
      for LJob in LJobs.JobData do
      begin
        Writeln(Format('%S - %S ', [LJob.JobTitle, LJob.OrganizationName]));
      end;
    finally
      LJobs.Free;
    end;
  finally
    LJobsClient.Free;
  end;
end;

procedure Main();
var
  LClient: TGeonamesClient;
  LGeoNames: TGeonames;
  LMessage, LServerMessage: TStatusMessage;
begin
  LClient := TGeonamesClient.Create('http://api.geonames.org');
  try
    LClient.SetHttpClient('idHttp');
    LGeoNames := LClient.GetNeighbours(597427, 'demo');
    LMessage := TStatusMessage.Create();
    try
      if (Assigned(LGeoNames.geonames)) and (LGeoNames.geonames.Count > 0) then
      begin
        Writeln(Format('Total Count %D', [LGeoNames.totalResultsCount]));
        Writeln(Format('First country name: %S', [LGeoNames.geonames[0].countryName]));
        Writeln(Format('First country latitude: %D', [LGeoNames.geonames[0].lat]));
        Writeln(Format('First country longitude: %D', [LGeoNames.geonames[0].lng]));
        Writeln(Format('First country code: %S', [LGeoNames.geonames[0].countryCode]));
        Writeln(Format('First country population: %D', [LGeoNames.geonames[0].population]));
      end;

      LMessage.status := TStatus.Create;
      LMessage.status.message := 'Testing';
      LMessage.status.value := 101;
      LServerMessage := LClient.GetStatus(LMessage);
      if Assigned(LServerMessage) then
      begin
        Writeln(LServerMessage.status.message);
        LServerMessage.Free;
      end;
    finally
      LGeoNames.Free;
      LMessage.Free;
    end;
  finally
    LClient.Free;
  end;

  //jobs
  PrintJobs();
end;

var
  s: string;
begin
  try
    ReportMemoryLeaksOnShutdown := True;
    Main();
    Readln(s);
  except
    on E: Exception do
    begin
      Writeln(E.ClassName, ': ', E.Message);
      Readln(s);
    end;
  end;
end.
