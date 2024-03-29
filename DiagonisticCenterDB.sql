USE [master]
GO
/****** Object:  Database [DiagnosticDB]    Script Date: 9/1/2018 9:48:54 PM ******/
CREATE DATABASE [DiagnosticDB]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'SharpDB', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL11.SQLEXPRESS\MSSQL\DATA\SharpDB.mdf' , SIZE = 3136KB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024KB )
 LOG ON 
( NAME = N'SharpDB_log', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL11.SQLEXPRESS\MSSQL\DATA\SharpDB_log.ldf' , SIZE = 784KB , MAXSIZE = 2048GB , FILEGROWTH = 10%)
GO
ALTER DATABASE [DiagnosticDB] SET COMPATIBILITY_LEVEL = 110
GO
IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [DiagnosticDB].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO
ALTER DATABASE [DiagnosticDB] SET ANSI_NULL_DEFAULT OFF 
GO
ALTER DATABASE [DiagnosticDB] SET ANSI_NULLS OFF 
GO
ALTER DATABASE [DiagnosticDB] SET ANSI_PADDING OFF 
GO
ALTER DATABASE [DiagnosticDB] SET ANSI_WARNINGS OFF 
GO
ALTER DATABASE [DiagnosticDB] SET ARITHABORT OFF 
GO
ALTER DATABASE [DiagnosticDB] SET AUTO_CLOSE ON 
GO
ALTER DATABASE [DiagnosticDB] SET AUTO_CREATE_STATISTICS ON 
GO
ALTER DATABASE [DiagnosticDB] SET AUTO_SHRINK OFF 
GO
ALTER DATABASE [DiagnosticDB] SET AUTO_UPDATE_STATISTICS ON 
GO
ALTER DATABASE [DiagnosticDB] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO
ALTER DATABASE [DiagnosticDB] SET CURSOR_DEFAULT  GLOBAL 
GO
ALTER DATABASE [DiagnosticDB] SET CONCAT_NULL_YIELDS_NULL OFF 
GO
ALTER DATABASE [DiagnosticDB] SET NUMERIC_ROUNDABORT OFF 
GO
ALTER DATABASE [DiagnosticDB] SET QUOTED_IDENTIFIER OFF 
GO
ALTER DATABASE [DiagnosticDB] SET RECURSIVE_TRIGGERS OFF 
GO
ALTER DATABASE [DiagnosticDB] SET  ENABLE_BROKER 
GO
ALTER DATABASE [DiagnosticDB] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO
ALTER DATABASE [DiagnosticDB] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO
ALTER DATABASE [DiagnosticDB] SET TRUSTWORTHY OFF 
GO
ALTER DATABASE [DiagnosticDB] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO
ALTER DATABASE [DiagnosticDB] SET PARAMETERIZATION SIMPLE 
GO
ALTER DATABASE [DiagnosticDB] SET READ_COMMITTED_SNAPSHOT OFF 
GO
ALTER DATABASE [DiagnosticDB] SET HONOR_BROKER_PRIORITY OFF 
GO
ALTER DATABASE [DiagnosticDB] SET RECOVERY SIMPLE 
GO
ALTER DATABASE [DiagnosticDB] SET  MULTI_USER 
GO
ALTER DATABASE [DiagnosticDB] SET PAGE_VERIFY CHECKSUM  
GO
ALTER DATABASE [DiagnosticDB] SET DB_CHAINING OFF 
GO
ALTER DATABASE [DiagnosticDB] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF ) 
GO
ALTER DATABASE [DiagnosticDB] SET TARGET_RECOVERY_TIME = 0 SECONDS 
GO
USE [DiagnosticDB]
GO
/****** Object:  StoredProcedure [dbo].[sp_GetReportByTest]    Script Date: 9/1/2018 9:48:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


create proc [dbo].[sp_GetReportByTest]
 @FromDate datetime ,
 @ToDate datetime
 as
 begin	
select test.testName, coalesce(sum(myTable.TestCount),0) as TotalTest, coalesce(sum(myTable.Amount),0) as TotalAmount from TestSetUp test 
left join
(
   select req.TestID ,count(req.TestID)
    as TestCount,sum(test.testFee) as Amount from TestSetUp test 
        join PatientRequestTest req 
       on test.ID=req.TestID
	    join Patient patient 
	    on req.patientID=patient.ID
		where BillDate>=@FromDate  and BillDate<= @ToDate
		group by req.TestID
		) as myTable

on test.ID=myTable.TestID

group by test.testName

end




GO
/****** Object:  StoredProcedure [dbo].[sp_GetReportByType]    Script Date: 9/1/2018 9:48:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
	   
	create proc [dbo].[sp_GetReportByType]

	@FromDate datetime ,
    @ToDate datetime   
    as
    begin
	
	select  typ.typeName,coalesce(sum(myTable.TotalNoOfTest) ,0) as totalTest, 
	        Coalesce(sum(myTable.testTotal),0) as TotalAmount 
	        from TestType typ left join

    (select test.typeID,sum(testFee) as testTotal ,count(test.ID) as TotalNoOfTest   
	           from  PatientRequestTest req join TestSetUp test
               on req.TestID=test.ID
		       join Patient patient 
		       on req.patientID=patient.ID
		       where BillDate>=@FromDate  and BillDate<= @ToDate
		       group by test.typeID
		   )   as myTable

		       on typ.ID=myTable.typeID
		       group by typ.typeName
		    
		   end



GO
/****** Object:  StoredProcedure [dbo].[Sp_PatientDetailsUpdate]    Script Date: 9/1/2018 9:48:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create proc [dbo].[Sp_PatientDetailsUpdate]
		@BillNo varchar(250),
		@PaidBill money
		as
		begin
		update Patient set PaidBill=case 
		                            when(TotalFee-PaidBill)=0 and @PaidBill>TotalFee then PaidBill
		                            when @PaidBill>TotalFee and @PaidBill>PaidBill then PaidBill
									when @PaidBill>TotalFee then 0
									when @PaidBill> TotalFee-PaidBill then PaidBill
									when (TotalFee-PaidBill)=0 then TotalFee
									when TotalFee=@PaidBill then TotalFee
									when (TotalFee-PaidBill)=@PaidBill then TotalFee
									else
									PaidBill+@PaidBill
									end
       where BillNo=@BillNo
		end 
								



GO
/****** Object:  StoredProcedure [dbo].[SP_PatientPaymentByBillNo]    Script Date: 9/1/2018 9:48:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 Create proc [dbo].[SP_PatientPaymentByBillNo]
		 @billNo varchar(250)
		 as 
		 begin
		 select test.testName testName,test.testFee as testFee,p.BillDate as BillDate,p.BillNo as BillNo,
		        p.TotalFee as TotalFee,p.PaidBill as PaidBill 
		        from PatientRequestTest req join Patient p
		        on req.patientID=p.ID
				join TestSetUp test
				on req.TestID=test.ID where p.BillNo=@billNo

        end 






GO
/****** Object:  StoredProcedure [dbo].[sp_UnPaidBillReport]    Script Date: 9/1/2018 9:48:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




 create proc [dbo].[sp_UnPaidBillReport]
 @FromDate datetime,
 @ToDate datetime
 as
 begin

  select   p.BillNo as BillNo, p.MobileNO as MobileNo,p.patientName as PatientName,
           (p.TotalFee-p.PaidBill) as UnPaidBill
           from Patient p
           where  (p.TotalFee-p.PaidBill)!= 0 and BillDate>=@FromDate  and BillDate<= @ToDate

 end



    select * from Patient    

	select * from TestType

	select * from TestSetUp

	select * from PatientRequestTest
GO
/****** Object:  Table [dbo].[Patient]    Script Date: 9/1/2018 9:48:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Patient](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[patientName] [varchar](50) NOT NULL,
	[DateOfBirth] [datetime] NULL,
	[MobileNO] [int] NOT NULL,
	[BillNo] [nvarchar](250) NOT NULL,
	[BillDate] [date] NOT NULL,
	[TotalFee] [money] NULL,
	[PaidBill] [money] NULL,
 CONSTRAINT [PK_Patient_ID] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY],
 CONSTRAINT [UQ_Patient_BillNo] UNIQUE NONCLUSTERED 
(
	[BillNo] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[PatientRequestTest]    Script Date: 9/1/2018 9:48:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PatientRequestTest](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[patientID] [int] NULL,
	[TestID] [int] NULL,
PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[TestSetUp]    Script Date: 9/1/2018 9:48:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[TestSetUp](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[testName] [varchar](50) NOT NULL,
	[testFee] [money] NOT NULL,
	[typeID] [int] NULL,
 CONSTRAINT [PK_Test_ID] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[TestType]    Script Date: 9/1/2018 9:48:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[TestType](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[typeName] [varchar](50) NOT NULL,
 CONSTRAINT [PK_Type_ID] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  View [dbo].[VW_TestDetails]    Script Date: 9/1/2018 9:48:54 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
   create view [dbo].[VW_TestDetails] 
   as
   select test.testName as [Test],test.testFee as Fee,typ.typeName as [Type] 
	        from TestType  typ 
            join TestSetUp  test on typ.ID = test.typeID


   --------------------------------------Store Procedure----------------------------------------
 

GO
ALTER TABLE [dbo].[PatientRequestTest]  WITH CHECK ADD  CONSTRAINT [FK_TestRequest_PatientID] FOREIGN KEY([patientID])
REFERENCES [dbo].[Patient] ([ID])
GO
ALTER TABLE [dbo].[PatientRequestTest] CHECK CONSTRAINT [FK_TestRequest_PatientID]
GO
ALTER TABLE [dbo].[PatientRequestTest]  WITH CHECK ADD  CONSTRAINT [FK_TestRequest_TestID] FOREIGN KEY([TestID])
REFERENCES [dbo].[TestSetUp] ([ID])
GO
ALTER TABLE [dbo].[PatientRequestTest] CHECK CONSTRAINT [FK_TestRequest_TestID]
GO
ALTER TABLE [dbo].[TestSetUp]  WITH CHECK ADD  CONSTRAINT [FK_Test_Type_ID] FOREIGN KEY([typeID])
REFERENCES [dbo].[TestType] ([ID])
GO
ALTER TABLE [dbo].[TestSetUp] CHECK CONSTRAINT [FK_Test_Type_ID]
GO
USE [master]
GO
ALTER DATABASE [DiagnosticDB] SET  READ_WRITE 
GO
